CREATE OR REPLACE FUNCTION add_teacher() RETURNS TRIGGER AS $checkTeacher$
    BEGIN
        IF (SELECT exists(SELECT 1 FROM teacherspecialisation
            WHERE teacherspecialisation.courseid = NEW.courseid
            AND teacherspecialisation.teacherid = NEW.teacherid))
        THEN
            RETURN NEW;
        ELSE
            RAISE EXCEPTION 'Преподаватель не может вести занятие по этому курсу';
        END IF;
    END
$checkTeacher$ LANGUAGE  plpgsql;

CREATE TRIGGER teacher_trigger
 BEFORE INSERT OR UPDATE
 ON lesson
 FOR EACH ROW
 EXECUTE PROCEDURE add_teacher();
