CREATE OR REPLACE PROCEDURE course_enroll(IN course_name VARCHAR(20),
                                            IN payment_id INT,
                                            IN passport_in CHAR(10),
                                            IN date_enroll DATE,
                                            INOUT result varchar(300))
LANGUAGE plpgsql
AS $CourseProcedure$
    DECLARE
        course_price    DECIMAL(8,2);
        course_parts    INT;
        cert_num        INT;
        group_amount    INT;
        course_id       INT;
        student_id      INT;
        sch_id          INT;
        sch_date        DATE;
        curator_id      INT;
        group_id        INT;
        course_days     INT;
        aud_id          INT;
        err             INT;
        curs            CURSOR FOR SELECT s.studentid, partid as course_part, generalid as course_general, mark
                            FROM certificate cert JOIN coursecomposition comp ON cert.courseid = comp.partid
                            JOIN student s on cert.studentid = s.studentid
                            WHERE passport = passport_in
                              AND cert.mark = 'pass'
                              AND comp.generalid = (SELECT courseid FROM course WHERE course.name = course_name);
    BEGIN
        err = 0;
        result = '';
        -- Проверка переданных в функцию параметров
        SELECT studentid INTO student_id FROM student WHERE student.passport = passport_in;
        IF student_id IS NULL THEN
            result = 'Не существует слушателя с паспортом ' || passport_in || '. ';
            err = 1;
        END IF;
        SELECT courseid INTO course_id FROM course WHERE course.name = course_name;
        IF course_id IS NULL THEN
            result = result || 'Курса с названием ' || course_name || ' не существует. ';
            err = 1;
        END IF;
        IF NOT exists(SELECT 1 FROM coursepayment WHERE coursepayment.cpid = payment_id
                                                    AND coursepayment.studentid = student_id) THEN
            result = result || 'Квитанции об оплате с номером '|| payment_id ||' у студента ' || passport_in || ' не существует.';
            err = 1;
        END IF;
        IF err = 1 THEN
            RETURN;
        END IF;
        --RAISE NOTICE 'Входные параметры верны';
        -- Проверка отстутсвия сертификата об успешном прохождении курса
        IF exists(SELECT 1 FROM certificate WHERE certificate.courseid = course_id
                                                  AND certificate.studentid = student_id
                                                  AND certificate.mark = 'pass') THEN
                result = 'Студент ' || passport_in || ' уже имеет сертификат о прохождении курса ' || course_name;
                RETURN;
        END IF;
        --RAISE NOTICE 'Сертификата нет';
        -- Проверка наличия 25% сертификатов при записи на междисциплинарный курс
        IF exists(SELECT 1 FROM intercourse WHERE intercourse.courseid = course_id) THEN
            SELECT count(coursecomposition.partid) INTO course_parts FROM coursecomposition
                                            WHERE coursecomposition.generalid = course_id;
            cert_num = 0;
            FOR record IN curs LOOP
                IF record.mark = 'pass' THEN
                    cert_num = cert_num + 1;
                END IF;
            END LOOP;
            IF CAST(cert_num as float4) / CAST(course_parts as float4) < 0.25 THEN
                result = 'Недостаточно изученных курсов - ' ||
                         round(CAST(cert_num as float4) / CAST(course_parts as float4) * 100) || '%';
                RETURN;
            END IF;
        END IF;
        -- Корректировка цены, если слушатель повторно будет изучать курс
        SELECT cost INTO course_price FROM course WHERE course.courseid = course_id;
        IF exists(SELECT 1 FROM certificate WHERE certificate.courseid = course_id
                                                  AND certificate.studentid = student_id
                                                  AND certificate.mark = 'fail') THEN
            course_price = course_price * 0.5;
        END IF;
        -- Проверка оплаты курса
        IF (SELECT coursepayment.payment FROM coursepayment
                                            WHERE coursepayment.cpid = payment_id) < course_price THEN
            result = 'Стоимость курса ' || course_price || ' превышает внесенную сумму';
            RETURN;
        END IF;
        --RAISE NOTICE 'Слушатель может быть добавлен в группу';
        -- Поиск ближайшей даты начала занятий
        SELECT min(schedule.scheduleid) INTO sch_id FROM schedule
            JOIN courseschedule cs on schedule.scheduleid = cs.scheduleid
            WHERE courseid = course_id AND startdate > date_enroll;
        -- Если нет ближайших занятий, добавляю записи в таблицы
        IF sch_id IS NULL THEN
            RAISE NOTICE 'Добавление курса в расписание и создание группы';
            SELECT days INTO course_days FROM course WHERE courseid = course_id;
            -- Поиск куратора
            WITH teacher_holiday AS (
                    SELECT teacherid FROM teacherholiday
                        JOIN holiday h ON h.holidayid = teacherholiday.holidayid
                        WHERE (h.holidate >= date_enroll + 30 AND h.holidate <= date_enroll + 30 + course_days)
                )
                SELECT max(teacherid) INTO curator_id FROM teacherspecialisation WHERE courseid = course_id
                    EXCEPT (SELECT teacherid FROM "Group" UNION SELECT teacherid FROM teacher_holiday);
            IF curator_id IS NULL THEN
                err = 1;
                result = 'Нет подходящего куратора для новой группы. ';
            ELSE
                RAISE NOTICE 'Куратор найден';
            END IF;
            -- Поиск аудитории
            SELECT max(audiencespec.audienceid) INTO aud_id FROM audiencespec
                LEFT JOIN groupschedule gs on audiencespec.audienceid = gs.audienceid
                LEFT JOIN schedule s on gs.scheduleid = s.scheduleid
                WHERE audiencespec.courseid = course_id
                  AND (startdate + course_days < date_enroll + 30
                           OR startdate IS NULL OR startdate > date_enroll + 30 + course_days);
            IF aud_id IS NULL THEN
                err = 1;
                result = result || 'Нет свободной подходящей аудитории.';
            ELSE
                RAISE NOTICE 'Аудитория найдена';
            END IF;
            IF err = 1 THEN
                RETURN;
            END IF;
            -- Вставка записей в таблицы
            INSERT INTO schedule VALUES (default, date_enroll + 30); -- расписание
            SELECT scheduleid INTO sch_id FROM schedule WHERE startdate = date_enroll + 30;
            INSERT INTO courseschedule(courseid, scheduleid) VALUES (course_id, sch_id); -- расписание курса
            INSERT INTO "Group" VALUES (default, curator_id, 1); -- группа
            SELECT number INTO group_id FROM "Group" WHERE teacherid = curator_id;
            INSERT INTO groupstudent VALUES (group_id, student_id); -- студент группы
            INSERT INTO groupschedule(groupschid, number, audienceid, courseid, scheduleid)
                VALUES (default, group_id, aud_id, course_id, sch_id); -- расписание группы
            SELECT startdate INTO sch_date FROM schedule WHERE scheduleid = sch_id;
            RAISE NOTICE 'Создается группа с номером %', group_id;
            CALL add_lessons(group_id, course_name, sch_date, result);
            RAISE NOTICE 'Занятия: %',result;
        -- Если же уже создана группа по курсу
        ELSE
            SELECT startdate INTO sch_date FROM schedule WHERE scheduleid = sch_id;
            RAISE NOTICE 'Ближайшая дата начала занятий - %', sch_date;
            SELECT days INTO course_days FROM course WHERE courseid = course_id;
            -- Проверка, что слушатель еще не записан на курс
            IF exists(SELECT 1 FROM groupschedule JOIN groupstudent g on groupschedule.number = g.number
                WHERE courseid = course_id AND studentid = student_id AND scheduleid = sch_id) THEN
                    result = 'Слушатель ' || passport_in || ' уже записан в группу по курсу ' || course_name;
                    RETURN;
            END IF;
            -- Проверка заполненности группы
            WITH grp_sch AS (
                SELECT number FROM groupschedule WHERE courseid = course_id AND scheduleid = sch_id
            )
            SELECT max("Group".number) INTO group_id FROM grp_sch
                JOIN "Group" ON grp_sch.number = "Group".number
                WHERE amount <= 14;
            -- Если все группы заполнены, надо создать новую
            IF group_id IS NULL THEN
                RAISE NOTICE 'Группы заполнены, создается новая группа';
                -- Поиск куратора
                WITH teacher_holiday AS (
                    SELECT teacherid FROM teacherholiday
                        JOIN holiday h ON h.holidayid = teacherholiday.holidayid
                        WHERE (h.holidate >= sch_date AND h.holidate <= sch_date + course_days)
                )
                SELECT max(teacherid) INTO curator_id FROM teacherspecialisation WHERE courseid = course_id
                    EXCEPT (SELECT teacherid FROM "Group" UNION SELECT teacherid FROM teacher_holiday);
                IF curator_id IS NULL THEN
                    err = 1;
                    result = 'Нет подходящего куратора для новой группы. ';
                ELSE
                    RAISE NOTICE 'Куратор найден';
                END IF;
                -- Поиск аудитории
                SELECT max(audiencespec.audienceid) INTO aud_id FROM audiencespec
                    LEFT JOIN groupschedule gs on audiencespec.audienceid = gs.audienceid
                    LEFT JOIN schedule s on gs.scheduleid = s.scheduleid
                    WHERE audiencespec.courseid = course_id
                      AND (startdate + course_days < sch_date
                               OR startdate IS NULL OR startdate > sch_date + course_days);
                IF aud_id IS NULL THEN
                    err = 1;
                    result = result || 'Нет свободной подходящей аудитории.';
                ELSE
                    RAISE NOTICE 'Аудитория найдена';
                END IF;
                IF err = 1 THEN
                    RETURN;
                END IF;
                -- Вставка записей
                INSERT INTO "Group" VALUES (default, curator_id, 1); -- группа
                SELECT max(number) INTO group_id FROM "Group" WHERE teacherid = curator_id;
                INSERT INTO groupstudent VALUES (group_id, student_id); -- студент группы
                INSERT INTO groupschedule VALUES (default, group_id, aud_id, course_id, sch_id); -- расписание группы
                SELECT startdate INTO sch_date FROM schedule WHERE scheduleid = sch_id;
                RAISE NOTICE 'Создается группа с номером %', group_id;
                CALL add_lessons(group_id, course_name, sch_date, result); -- добавление занятий
                RAISE NOTICE 'Занятия: %',result;
            ELSE
                SELECT startdate INTO sch_date FROM schedule WHERE scheduleid = sch_id;
                RAISE NOTICE 'Найдена группа % с началом занятий %', group_id, sch_date;
                -- Если группа уже есть, добавить туда слушателя
                INSERT INTO groupstudent VALUES (group_id, student_id); -- студент группы
                -- Добавление слушателя в группу
                SELECT amount INTO group_amount FROM "Group" WHERE number = group_id;
                UPDATE "Group"
                SET amount = group_amount + 1
                WHERE number = group_id;
            END IF;
        END IF;
        result = 'Слушатель ' || passport_in || ' добавлен в группу ' || group_id || ' по курсу ' || course_name;
    END
$CourseProcedure$;

DELETE FROM certificate;
DELETE FROM coursepayment;

do $$
    declare
        result varchar(300);
    begin
        -- такого паспорта нет
        CALL course_enroll('Math', 1, '1111111112',current_date, result);
        raise notice 'RES: "%"', result;
        -- такого курса нет
        CALL course_enroll('ABAB', 1, '1111111111', current_date, result);
        raise notice 'RES: "%"', result;
        -- нет такой оплаты
        CALL course_enroll('Math', 2, '1111111111', current_date, result);
        raise notice 'RES: "%"', result;
         -- нет ничего
        CALL course_enroll('Russian', 2, '1111111112', current_date, result);
        raise notice 'RES: "%"', result;
        -- Недостаточно сертификатов
        INSERT INTO coursepayment(cpid, studentid, payment, paymentdate) VALUES (1, 1, 20000.00, current_date);
        CALL course_enroll('Languages', 1, '1111111111',current_date, result);
        raise notice 'RES: "%"', result;
        -- Уже есть сертификат
        INSERT INTO certificate VALUES (default, 1, 4, 'pass', current_date);
        CALL course_enroll('French', 1, '1111111111',current_date, result);
        raise notice 'RES: "%"', result;
        -- Недостаточно оплаты
        INSERT INTO certificate VALUES (default, 1, 2, 'pass', current_date);
        CALL course_enroll('Languages', 1, '1111111111',current_date, result);
        raise notice 'RES: "%"', result;
        -- Нет куратора и аудитории
        CALL course_enroll('Math', 1, '1111111111','2021-02-02', result);
        raise notice 'RES: "%"', result;
        -- добавление при отсутствии расписания
        INSERT INTO audiencespec VALUES (100, 1);
        INSERT INTO teacherspecialisation VALUES (1, 1);
        CALL course_enroll('Math', 1, '1111111111','2021-02-02', result);
        raise notice 'RES: "%"', result;
    end;
$$;

do $$
    declare
        result varchar(300);
    begin
        -- ИЗМЕНИТЬ КОЛИЧЕСТВО УЧАСТНИКОВ НА 14 --
        -- добавления слушателя в созданную группу
        INSERT INTO coursepayment(cpid, studentid, payment, paymentdate) VALUES (2, 2, 10000.00, current_date);
        CALL course_enroll('Math', 2, '2222222222','2021-02-20', result);
        raise notice 'RES: "%"', result;
        -- добавление того же слушателя в группу с максимальной заполненностью
        CALL course_enroll('Math', 2, '2222222222','2021-02-20', result);
        raise notice 'RES: "%"', result;
        -- Попытка создания новой группы, так как старая занята, но нет куратора и аудитории
        INSERT INTO coursepayment(cpid, studentid, payment, paymentdate) VALUES (3, 3, 10000.00, current_date);
        CALL course_enroll('Math', 3, '3333333333','2021-02-20', result);
        raise notice 'RES: "%"', result;
        -- У куратора нерабочий день
        INSERT INTO teacherspecialisation VALUES (2, 1);
        INSERT INTO audiencespec VALUES (200, 1);
        INSERT INTO holiday VALUES (1, '2021-03-08');
        INSERT INTO teacherholiday VALUES  (1, 2);
        CALL course_enroll('Math', 3, '3333333333','2021-02-20', result);
        raise notice 'RES: "%"', result;
        -- Создается новая группа
        DELETE FROM teacherholiday WHERE teacherid = 2;
        CALL course_enroll('Math', 3, '3333333333','2021-02-20', result);
        raise notice 'RES: "%"', result;
        -- Добавление того же слушателя в группу, где есть места
        CALL course_enroll('Math', 3, '3333333333','2021-02-20', result);
        raise notice 'RES: "%"', result;
    end
$$;

DELETE FROM lesson WHERE number = 17;
DELETE FROM "Group" WHERE number = 17;
DELETE FROM groupschedule WHERE number = 17;
DELETE FROM groupstudent WHERE number = 17;
DELETE FROM teacherschedule WHERE teacherid = 2;