TRUNCATE course CASCADE ;
TRUNCATE teacher CASCADE;
TRUNCATE teacherspecialisation;
TRUNCATE "Group" CASCADE ;
TRUNCATE audience CASCADE;
TRUNCATE schedule CASCADE ;
TRUNCATE courseschedule CASCADE ;
TRUNCATE lesson CASCADE ;
TRUNCATE groupschedule CASCADE;

INSERT INTO course(courseid, name, cost, days) VALUES
                    (1, 'Math', 10000.00, 10),
                    (2, 'English', 9000.00, 10);
INSERT INTO teacher(teacherid, passport,firstname, lastname, middlename, category) VALUES
                    (1, '1111111111', 'Ivan', 'Ivanov', 'Ivanovich', 2),
                    (2, '2222222222','Vladimir', 'Ivanov', 'Nikolaevich', 5);
INSERT INTO teacherspecialisation(teacherid, courseid) VALUES
                                    (1, 1),
                                    (2, 2);
INSERT INTO "Group"(number, teacherid, amount) VALUES (1, 1, 9);
INSERT INTO schedule(scheduleid, startdate) VALUES (1, '2021-02-01');
INSERT INTO courseschedule(scheduleid, courseid) VALUES (1, 1);

INSERT INTO audience(audienceid, places) VALUES
                    (100, 10),
                    (200, 5);
INSERT INTO audiencespec(audienceid, courseid) VALUES
                        (100, 1),
                        (200, 2);
SELECT * FROM audience;
SELECT * FROM audiencespec;
INSERT INTO groupschedule(groupschid, number, audienceid, courseid, scheduleid) VALUES
                        (1, 1, 100, 1, 1);
SELECT * FROM groupschedule;
--INSERT INTO groupschedule VALUES (2, 1, 200, 1, 1);
SELECT * FROM groupschedule;
--INSERT INTO groupschedule VALUES (3, 1, 200, 2, 1);
SELECT * FROM groupschedule;

SELECT * FROM teacher;
SELECT * FROM teacherspecialisation;
SELECT * FROM course;
--INSERT INTO lesson VALUES (1, 2, 1, 1, 1, current_date);
INSERT INTO lesson VALUES (1, 2, 1, 2, 1, current_date);
SELECT * FROM lesson;
INSERT INTO lesson VALUES (1, 1, 1, 1, 1, current_date);
SELECT * FROM lesson;
INSERT INTO lesson VALUES (2, 1, 1, 1, 1, current_date);
SELECT * FROM lesson;

INSERT INTO student(studentid, passport, firstname, lastname, middlename) VALUES (1, 'Ivan', 'Popov', 'Igorevich');
INSERT INTO student(studentid, passport, firstname, lastname, middlename) VALUES (2, 'Irina', 'Medvedeva', 'Igorevna');
INSERT INTO groupstudent(number, studentid) VALUES (1, 1);
INSERT INTO groupstudent(number, studentid) VALUES (1, 2);
SELECT * FROM student;
SELECT * FROM certificate;
DELETE FROM exam WHERE studentid = 1;
DELETE FROM exampayment WHERE studentid = 1;
DELETE FROM certificate WHERE studentid = 1;
--INSERT INTO exam VALUES (1, 1, NULL, 1, 2, NULL, 'fail', '2020-03-01'); /*Еще не было попыток сдачи*/
INSERT INTO exam(examid, courseid, epid, studentid, try, cost, mark, trydate) VALUES (1, 1, NULL, 1, 1, NULL, 'fail', '2020-03-01');
--INSERT INTO exam VALUES (2, 1, NULL, 1, 2, 100.00, 'fail', '2020-03-02'); /* Платный 2ой экз */
--INSERT INTO exam VALUES (2, 1, NULL, 1, 3, NULL, 'fail', '2020-03-02'); /*Попытка добавить 3ю, но была 1*/
INSERT INTO exam VALUES (2, 1, NULL, 1, 2, NULL, 'fail', '2020-03-02');
INSERT INTO exam VALUES (3, 1, NULL, 1, 3, NULL, 'fail', '2020-03-03');
INSERT INTO exam VALUES (4, 1, NULL, 1, 4, NULL, 'fail', '2020-03-04');
--INSERT INTO exam VALUES (5, 1, NULL, 1, 5, NULL, 'fail', '2020-03-05'); /*Нет стоимости*/
--INSERT INTO exam VALUES (5, 1, NULL, 1, 5, 100.00, 'fail', '2020-03-05'); /*Нет оплаты*/
INSERT INTO exampayment(epid, studentid, payment, paydate) VALUES (1, 1, 50.00, '2020-03-05');
--INSERT INTO exam VALUES (5, 1, 1, 1, 5, 100.00, 'fail', '2020-03-05'); /*Внесено меньше денег*/
INSERT INTO exampayment(epid, studentid, payment, paydate) VALUES (2, 1, 100.00, '2020-03-05');
INSERT INTO exam VALUES (5, 1, 2, 1, 5, 100.00, 'pass', '2020-03-05');
SELECT * FROM certificate;
--INSERT INTO exam VALUES (6, 1, 2, 1, 6, 100.00, 'fail', '2020-03-06'); /*Есть сертификат об успешной сдаче*/
DELETE FROM certificate WHERE certificate.studentid = 1;
DELETE FROM exam WHERE exam.examid = 5;
INSERT INTO exam VALUES (5, 1, 2, 1, 5, 100.00, 'fail', '2020-03-05');
--INSERT INTO exam VALUES (6, 1, 2, 1, 6, 100.00, 'fail', '2020-03-06');
INSERT INTO exampayment(epid, studentid, payment, paydate) VALUES (3, 1, 100.00, '2020-03-06');
INSERT INTO exam VALUES (6, 1, 3, 1, 6, 100.00, 'fail', '2020-03-06');
INSERT INTO exampayment(epid, studentid, payment, paydate) VALUES (4, 1, 100.00, '2020-03-06');
INSERT INTO exam VALUES (7, 1, 4, 1, 7, 100.00, 'fail', '2020-03-07');
SELECT * FROM exampayment;
SELECT * FROM exam;
--INSERT INTO exam VALUES (11, 1, NULL, 1, 1, NULL, 'pass', '2020-03-02'); /*Сертификат по курсу с большей датой уже есть*/
INSERT INTO exam VALUES (11, 2, NULL, 2, 1, NULL, 'pass', '2020-04-01');

INSERT INTO course(courseid, name, cost, days) VALUES (3, 'Bachata', 5000.00, 30);
INSERT INTO course VALUES (4, 'Salsa', 4000.00, 30);
INSERT INTO course VALUES (5, 'Waltz', 3000.00, 20);
INSERT INTO course VALUES (6, 'Classic Dancing', 9600.00, 60);
INSERT INTO intercourse VALUES (6);
INSERT INTO singlecourse VALUES (3), (4), (5);
INSERT INTO coursecomposition(partid, generalid) VALUES (3, 6), (4, 6), (5, 6);

DELETE FROM groupstudent;
DELETE FROM coursepayment;





INSERT INTO course(courseid, name, cost, days) VALUES
                    (1, 'Math', 10000.00, 10),
                    (2, 'English', 9000.00, 10),
                    (3, 'Physics', 10000.00, 20),
                    (4, 'French', 12000.00, 30),
                    (6, 'Languages', 30000.00, 60),
                    (5, 'Chineese', 15000.00, 30),
                    (7, 'Japanese', 15000.00, 5),
                    (8, 'Ukrainian', 8000.00, 7);
INSERT INTO singlecourse(courseid) VALUES (1), (2), (3), (4), (5), (7), (8);
INSERT INTO intercourse(courseid) VALUES (6);
INSERT INTO coursecomposition(partid, generalid) VALUES (2, 6),
                                                        (4, 6),
                                                        (5, 6),
                                                        (7, 6),
                                                        (8, 6);
INSERT INTO teacher(teacherid, passport,firstname, lastname, middlename, category) VALUES
                    (1, '1111111111', 'Ivan', 'Ivanov', 'Ivanovich', 2),
                    (2, '2222222222', 'Vladimir', 'Ivanov', 'Nikolaevich', 5);
                    --(3, '3333333333', 'Nikita', 'Fein', 'Sergeevich', 1),
                    --(4, '4444444444', 'Viktoria', 'Krasina', 'Nikitichna', 3);
INSERT INTO teacherspecialisation(teacherid, courseid) VALUES
                                                              (2, 2);
                                                              --(3, 3),
                                                              --(4, 4),
                                                              --(4, 2);
INSERT INTO student(studentid, passport, firstname, lastname, middlename) VALUES (1, '1111111111','Ivan', 'Popov', 'Igorevich'),
                                                                                 (2, '2222222222', 'Irina', 'Medvedeva', 'Igorevna'),
                                                                                 (3, '3333333333', 'Nikolay', 'Ivanov', 'Nikolaevich');
INSERT INTO audience(audienceid, places) VALUES
                                                (100, 15),
                                                (200, 15);
                                                --(300, 20);
INSERT INTO audiencespec(audienceid, courseid) VALUES
                                                      --(200, 4),
                                                      (200, 2);
                                                      --(300, 3);
INSERT INTO coursepayment(cpid, studentid, payment, paymentdate) VALUES (1, 1, 10000.00, current_date);
CALL course_enroll('Math', 1, '1111111112'); -- такого паспорта нет
CALL course_enroll('ABABA', 1, '1111111111'); -- такого курса нет
CALL course_enroll('Math', 2, '1111111111'); -- нет такой оплаты

INSERT INTO certificate(certid, studentid, courseid, mark, gotdate) VALUES (1, 1, 1, 'pass', current_date);
CALL course_enroll('Math', 1, '1111111111'); -- уже есть сертификат
DELETE FROM certificate WHERE certid = 1;
CALL course_enroll('Languages', 1, '1111111111'); -- недостаточно изученных курсов
CALL course_enroll('French', 1, '1111111111'); -- недостаточно внесено для оплаты

DELETE FROM teacherspecialisation WHERE courseid = 3;
CALL course_enroll('Physics', 1, '1111111111'); -- нет куратора
INSERT INTO teacherspecialisation VALUES (3, 3);

INSERT INTO audiencespec VALUES (200, 1);
CALL course_enroll('Math', 1, '1111111111');
CALL course_enroll('Math', 2, '2222222222');
CALL course_enroll('Math', 3, '3333333333');

INSERT INTO coursepayment(cpid, studentid, payment, paymentdate) VALUES (2, 2, 10000.00, current_date);
CALL course_enroll('Math', 2, '2222222222');

INSERT INTO coursepayment(cpid, studentid, payment, paymentdate) VALUES (3, 3, 30000.00, current_date);
CALL course_enroll('Math', 3, '3333333333');

INSERT INTO certificate VALUES (1, 3, 2, 'pass', current_date);
INSERT INTO teacherspecialisation VALUES (4, 5);
CALL course_enroll('Languages', 3, '3333333333'); -- нет аудитории
INSERT INTO audiencespec VALUES (100, 5);
CALL course_enroll('Languages', 3, '3333333333'); -- аудитория занята
INSERT INTO audiencespec VALUES (300, 5);
INSERT INTO certificate(certid, studentid, courseid, mark, gotdate) VALUES (2, 2, 2, 'pass', current_date);
INSERT INTO coursepayment(cpid, studentid, payment, paymentdate) VALUES (4, 2, 30000.00, current_date);
CALL course_enroll('Languages', 4, '2222222222');

DELETE FROM lesson;
DELETE FROM groupschedule;
DELETE FROM courseschedule;
DELETE FROM teacherschedule;
DELETE FROM schedule;

DELETE FROM groupstudent;
DELETE FROM "Group";
DELETE FROM coursepayment;
DELETE FROM certificate;

DELETE FROM audiencespec;
DELETE FROM audience;
DELETE FROM coursecomposition;
DELETE FROM singlecourse;
DELETE FROM intercourse;
DELETE FROM teacherholiday;
DELETE FROM teacherspecialisation;
DELETE FROM teacher;
DELETE FROM holiday;
DELETE FROM certificate;
DELETE FROM course;
DELETE FROM coursepayment;
DELETE FROM student;


INSERT INTO teacher VALUES (777, '5555555555', 'Ricardo', 'Milos', 'I', 1);
INSERT INTO course VALUES (777, 'Latina', 777.00, 7);
INSERT INTO teacherspecialisation VALUES (777, 777);
INSERT INTO audience VALUES (777, 20);
INSERT INTO audiencespec VALUES (777, 777);
INSERT INTO "Group" VALUES (777, 777, 10);
DELETE FROM lesson;
CALL add_lessons(777, 'Latina', '2021-06-11');
CALL add_lessons(111, 'Latinaswqdqd', '2021-06-11');
