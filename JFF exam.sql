CREATE OR REPLACE FUNCTION add_exam() RETURNS TRIGGER AS $checkExamPayment$
    DECLARE
        try_max     INT;
        sert_date   DATE;
        sert_mark   CHAR(4);
        last_paydate    DATE;
        last_pay    DECIMAL(6,2);
        last_exam   DATE;
    BEGIN
        SELECT max(gotdate) INTO sert_date FROM certificate WHERE certificate.studentid = NEW.studentid
                                                        AND certificate.courseid = NEW.studentid;
        SELECT mark INTO sert_mark FROM certificate WHERE certificate.studentid = NEW.studentid
                                                        AND certificate.courseid = NEW.studentid
                                                        AND certificate.gotdate = sert_date;
        SELECT paydate INTO last_paydate FROM exampayment WHERE exampayment.epid = NEW.epid;
        SELECT payment INTO last_pay FROM exampayment WHERE exampayment.epid = NEW.epid;
        SELECT max(trydate) INTO last_exam FROM exam WHERE exam.studentid = NEW.studentid;
        IF (sert_date IS NOT NULL AND sert_date > NEW.trydate) THEN
            RAISE EXCEPTION 'Неправильная дата';
        END IF;
        IF (sert_date IS NULL OR sert_mark = 'fail') THEN
            IF sert_date IS NULL THEN
                SELECT max(try) INTO try_max FROM exam WHERE exam.studentid = NEW.studentid
                                        AND exam.courseid = NEW.courseid;
            ELSE
                SELECT max(try) INTO try_max FROM exam WHERE exam.studentid = NEW.studentid
                                        AND exam.courseid = NEW.courseid AND exam.trydate > sert_date;
            END IF;
            IF (NEW.try > 1 AND last_exam IS NULL) THEN
                RAISE EXCEPTION 'Попыток сдачи еще не было';
            END IF;
            IF (NEW.try < 5 AND (NEW.cost IS NOT NULL OR NEW.cost != 0.00)) THEN
                RAISE EXCEPTION 'Первая поптыка и 3 пересдачи бесплатны';
            END IF;
            IF (try_max != NEW.try - 1) THEN
                RAISE EXCEPTION 'Неверный номер попытки сдачи';
            END IF;
            IF (NEW.try > 4 AND NEW.cost IS NULL) THEN
                RAISE EXCEPTION 'Начиная с 5 попытки экзамен платный';
            END IF;
             IF (NEW.try > 4 AND (last_pay IS NULL OR NEW.cost > last_pay)) THEN
                RAISE EXCEPTION 'Экзамен не оплачен';
            END IF;
            IF (NEW.try = 7 AND NEW.mark = 'fail') THEN
                INSERT INTO certificate(certid, studentid, courseid, mark, gotdate)
                    VALUES (default, NEW.studentid, NEW.courseid, 'fail', NEW.trydate);
            END IF;
            IF (NEW.mark = 'pass') THEN
                INSERT INTO certificate(certid, studentid, courseid, mark, gotdate)
                    VALUES (default, NEW.studentid, NEW.courseid, 'pass', NEW.trydate);
            END IF;
            RETURN NEW;
        END IF;
        IF (sert_date IS NOT NULL AND sert_mark = 'pass') THEN
            RAISE EXCEPTION 'Слушатель уже успешно сдал экзамен';
        END IF;
    END
$checkExamPayment$ LANGUAGE plpgsql;

CREATE TRIGGER exam_trigger
 BEFORE INSERT OR UPDATE
 ON exam
 FOR EACH ROW
 EXECUTE PROCEDURE add_exam();