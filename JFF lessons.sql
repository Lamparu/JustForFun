CREATE OR REPLACE PROCEDURE add_lessons(IN id_group INT,
                                        IN name_course VARCHAR(20),
                                        IN date_sch DATE,
                                        INOUT result varchar(100))
LANGUAGE plpgsql
AS $AddLessons$
    DECLARE
        id_course   INT;
        id_sch      INT;
        id_teacher  INT;
        id_aud      INT;
        course_days INT;
        gr_schedule INT;
        count       INT;
        err         INT;
    BEGIN
        SELECT courseid INTO id_course FROM course WHERE name = name_course;
        result = '';
        err = 0;
        -- Проверка существования курса
        IF id_course IS NULL THEN
            result = 'Не существует курса с названием ' || name_course || '. ';
            err = 1;
        END IF;
        -- Проверка существования группы
        IF NOT exists(SELECT 1 FROM "Group" WHERE number = id_group) THEN
            result = result || 'Не существует группы с номером ' || id_group || '.';
            err = 1;
        END IF;
        IF err = 1 THEN
            RETURN;
        END IF;
        RAISE NOTICE 'Дата начала занятий "%"', date_sch;
        SELECT days INTO course_days FROM course WHERE courseid = id_course;
        SELECT scheduleid INTO id_sch FROM schedule WHERE startdate = date_sch;
        -- Если нет расписания с заданной датой, то нужно добавить
        IF id_sch IS NULL THEN
            RAISE NOTICE 'Добавление нового расписания со стартом "%"', date_sch;
            -- Поиск свободной аудитории
            SELECT max(audiencespec.audienceid) INTO id_aud FROM audiencespec
                JOIN audience on audiencespec.audienceid = audience.audienceid
                LEFT JOIN groupschedule gs on audiencespec.audienceid = gs.audienceid
                LEFT JOIN schedule s on gs.scheduleid = s.scheduleid
                WHERE audiencespec.courseid = id_course
                    AND (startdate + course_days < date_sch OR startdate IS NULL OR startdate > date_sch + course_days)
                    AND places > (SELECT amount FROM "Group" WHERE "Group".number = id_group);
            IF id_aud IS NULL THEN
                result = 'Нет свободных подходящих аудиторий';
                RETURN;
            END IF;
            RAISE NOTICE 'Аудитория найдена';
            INSERT INTO schedule VALUES (default, date_sch);
            SELECT scheduleid INTO id_sch FROM schedule WHERE startdate = date_sch;
            INSERT INTO courseschedule VALUES (id_sch, id_course);
            INSERT INTO groupschedule VALUES (default, id_group, id_aud, id_course, id_sch);
            SELECT groupschid INTO gr_schedule FROM groupschedule
                WHERE courseid = id_course AND number = id_group AND courseid = id_course AND scheduleid = id_sch;
        ELSE
            SELECT groupschid INTO gr_schedule FROM groupschedule
                WHERE courseid = id_course AND number = id_group AND courseid = id_course AND scheduleid = id_sch;
            -- Если нет записи о расписании группы
            IF gr_schedule IS NULL THEN
                RAISE NOTICE 'Добавление записи в расписание группы';
                -- Поиск свободной аудитории
                SELECT max(audiencespec.audienceid) INTO id_aud FROM audiencespec
                    JOIN audience on audiencespec.audienceid = audience.audienceid
                    LEFT JOIN groupschedule gs on audiencespec.audienceid = gs.audienceid
                    LEFT JOIN schedule s on gs.scheduleid = s.scheduleid
                    WHERE audiencespec.courseid = id_course
                        AND (startdate + course_days < date_sch OR startdate IS NULL OR startdate > date_sch + 7)
                        AND places > (SELECT amount FROM "Group" WHERE "Group".number = id_group);
                IF id_aud IS NULL THEN
                    result = 'Нет свободных подходящих аудиторий';
                    RETURN;
                END IF;
                RAISE NOTICE 'Найдена подходящая аудитория';
                -- Если нет расписания курса
                IF NOT exists(SELECT 1 FROM courseschedule WHERE courseid = id_course AND scheduleid = id_sch) THEN
                    INSERT INTO courseschedule VALUES (id_sch, id_course);
                    RAISE NOTICE 'Добавлено расписание курса';
                END IF;
                INSERT INTO groupschedule VALUES (default, id_group, id_aud, id_course, id_sch);
                SELECT groupschid INTO gr_schedule FROM groupschedule
                    WHERE number = id_group AND courseid = id_course AND scheduleid = id_sch;
                RAISE NOTICE 'Добавлено расписание группы';
            END IF;
        END IF;
        -- Поиск преподавателя
        SELECT max(teacher.teacherid) INTO id_teacher FROM teacher
            JOIN teacherspecialisation ON teacher.teacherid = teacherspecialisation.teacherid
            LEFT JOIN teacherholiday ON teacher.teacherid = teacherholiday.teacherid
            LEFT JOIN holiday ON teacherholiday.holidayid = holiday.holidayid
            LEFT JOIN teacherschedule ON teacher.teacherid = teacherschedule.teacherid
            LEFT JOIN schedule ON teacherschedule.scheduleid = schedule.scheduleid
            WHERE courseid = id_course
                AND (startdate + course_days < date_sch OR startdate IS NULL OR startdate > date_sch + 7)
                AND ((holidate < date_sch AND holidate > date_sch + course_days) OR holidate IS NULL);
        IF id_teacher IS NULL THEN
            RAISE EXCEPTION 'Нет свободного преподавателя';
        END IF;
        RAISE NOTICE 'Найден свободный преподаватель';
        -- Добавление запиcей в таблицу Занятие и расписание преподавателя
        INSERT INTO teacherschedule VALUES (id_teacher, id_sch);
        count = 0;
        LOOP
            INSERT INTO lesson(lessonid, courseid, groupschid, teacherid, number, datelesson)
                VALUES (default, id_course, gr_schedule, id_teacher, id_group, date_sch + count);
            count = count + 1;
            EXIT WHEN count = course_days;
        END LOOP;
        result = 'Успешное создание ' || course_days || ' занятий для группы ' || id_group || ' по курсу ' || name_course;
    END
$AddLessons$;

DELETE FROM audiencespec WHERE audienceid = 666;
DELETE FROM teacherspecialisation WHERE teacherid = 666;
INSERT INTO teacherspecialisation VALUES (777, 777);

do $$
    declare
        result varchar(100);
    begin
        call add_lessons(1, 'Latina', '2021-05-05', result); -- нет группы №1
        raise notice 'RES: "%"', result;
        call add_lessons(777, 'Russian', '2021-05-05', result); -- нет курса Russian
        raise notice 'RES: "%"', result;
        call add_lessons(1, 'Russian', '2021-05-05', result); -- нет ни группы, ни курса
        raise notice 'RES: "%"', result;
        -- Добавление расписания занятий
        -- вставка в schedule, courseschedule, groupschedule, teacherschedule
        call add_lessons(777, 'Latina', '2021-05-05', result);
        raise notice 'RES: "%"', result;
        -- Расписание есть
        -- Попытка вставки записи в таблицу расписание группы, но нет свободной аудитории
        call add_lessons(666, 'Latina', '2021-05-05', result);
        raise notice 'RES: "%"', result;
        INSERT INTO audiencespec VALUES (666, 777);
    end;
$$;

SELECT * FROM schedule;
SELECT * FROM courseschedule;
SELECT * FROM groupschedule;
SELECT * FROM teacherschedule;

do $$
    declare
        result varchar(100);
    begin
        -- Расписание есть
        -- Попытка вставки записи в таблицу расписание группы, но нет свободного преподавателя
        call add_lessons(666, 'Latina', '2021-05-05', result);
        raise notice 'RES: "%"', result;
    end;
$$;

do $$
    declare
        result varchar(100);
    begin
        INSERT INTO teacherspecialisation VALUES (666, 777);
        -- Расписание есть, нет расписания группы, аудитория и преподаватель есть
        call add_lessons(666, 'Latina', '2021-05-05', result);
        raise notice 'RES: "%"', result;
    end;
$$;

do $$
    declare
        result varchar(100);
    begin
        INSERT INTO schedule VALUES (777, '2020-01-01');
        INSERT INTO courseschedule VALUES (777, 777);
        INSERT INTO groupschedule VALUES (777, 777, 777, 777, 777);
        DELETE FROM teacherspecialisation WHERE courseid = 777;
        -- Расписание есть, расписание группы есть, нет преподавателя
        call add_lessons(777, 'Latina', '2020-01-01', result);
        raise notice 'RES: "%"', result;
    end;
$$;

do $$
    declare
        result varchar(100);
    begin
        INSERT INTO schedule VALUES (777, '2020-01-01');
        INSERT INTO courseschedule VALUES (777, 777);
        INSERT INTO groupschedule VALUES (777, 777, 777, 777, 777);
        -- Расписание есть, расписание группы есть, есть преподаватель
        call add_lessons(777, 'Latina', '2020-01-01', result);
        raise notice 'RES: "%"', result;
    end;
$$;

INSERT INTO teacher VALUES (777, '5555555555', 'Ricardo', 'Milos', 'I', 1);
INSERT INTO teacher VALUES (666, '6666666666', 'El', 'Classico', 'Milos', 2);
INSERT INTO course VALUES (777, 'Latina', 777.00, 7);
INSERT INTO singlecourse VALUES (777);
INSERT INTO teacherspecialisation VALUES (777, 777);
INSERT INTO audience VALUES (777, 20);
INSERT INTO audience VALUES (666, 25);
INSERT INTO audiencespec VALUES (777, 777);
INSERT INTO "Group" VALUES (777, 777, 10);
INSERT INTO "Group" VALUES (666, 666, 5);

--INSERT INTO schedule VALUES (777, '2020-01-01');
--INSERT INTO courseschedule VALUES (777, 777);
--INSERT INTO groupschedule VALUES (777, 777, 777, 777, 777);