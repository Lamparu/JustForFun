CREATE OR REPLACE FUNCTION add_audience() RETURNS TRIGGER AS $checkAudience$
    DECLARE
        students_req    INT;
        students_au     INT;
    BEGIN
        SELECT audience.places INTO students_au FROM audience WHERE audience.audienceid = NEW.audienceid;
        SELECT "Group".amount INTO students_req FROM "Group" WHERE "Group".number = NEW.number;
        IF (SELECT exists(SELECT 1 FROM audiencespec
                WHERE audiencespec.audienceid = NEW.audienceid
                AND audiencespec.courseid = NEW.courseid)) THEN
            IF (students_req <= students_au) THEN
                RETURN NEW;
            ELSE
                RAISE EXCEPTION 'В аудитории недостаточно мест';
            END IF;
        ELSE
            RAISE EXCEPTION 'Аудитория не подходит для проведения занятий по этому курсу';
        END IF;
    END
$checkAudience$ LANGUAGE plpgsql;

CREATE TRIGGER audience_trigger
 BEFORE INSERT OR UPDATE
 ON groupschedule
 FOR EACH ROW
 EXECUTE PROCEDURE add_audience();