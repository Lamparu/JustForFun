-- 1
-- Инфа о работе учебного центра: курс (название), тип курса (межд или один),
-- кол-во слушателей (один слушатель как несколько может быть), кол-во занятий,
-- кол-во экзаменов, кол-во сертификатов

WITH tab_single AS (
        SELECT name, ('single') AS type FROM course
            JOIN singlecourse s on course.courseid = s.courseid
     ),
     tab_inter AS (
        SELECT name, ('inter') AS type FROM course
            JOIN intercourse i on course.courseid = i.courseid
     ),
     tab_students AS (
        SELECT DISTINCT coalesce(amount, 0) AS students, name FROM groupschedule
            RIGHT JOIN course c on groupschedule.courseid = c.courseid
            LEFT JOIN "Group" G on G.number = groupschedule.number
     ),
     tab_lessons AS (
         SELECT count(lessonid) AS lessons, name
         FROM lesson
            RIGHT JOIN course c on lesson.courseid = c.courseid
         GROUP BY name
     ),
     tab_cert AS (
         SELECT count(certid) AS certificates, name FROM certificate
            RIGHT JOIN course c on c.courseid = certificate.courseid WHERE (mark = 'pass' OR mark IS NULL)
         GROUP BY name
     ),
     tab_exam AS (
         SELECT count(examid) AS exams, name FROM exam
             RIGHT JOIN course c on c.courseid = exam.courseid
         GROUP BY name
     ),
     tab_courses AS (
         SELECT name, type FROM tab_inter UNION SELECT name, type from tab_single
     )
SELECT tab_courses.name AS course, type, sum(students) AS students, lessons, exams, certificates FROM tab_courses
    JOIN tab_students ON tab_courses.name = tab_students.name
    JOIN tab_lessons ON tab_courses.name = tab_lessons.name
    JOIN tab_exam ON tab_courses.name = tab_exam.name
    JOIN tab_cert ON tab_courses.name = tab_cert.name
GROUP BY  tab_courses.name, type, lessons, exams, certificates
ORDER BY type, tab_courses.name;

-- 2
-- Для преподов, которые провели занятие по мах кол-ву курсов,
-- получить отчет в виде: ФИО, квалификация, специализация,
-- кол-во разных курсов, общее кол-во всех занятий

WITH tab_spec AS (
    SELECT teacher.teacherid, array_agg(name) AS specialisation FROM teacher
        LEFT JOIN teacherspecialisation t on teacher.teacherid = t.teacherid
        LEFT JOIN course c on t.courseid = c.courseid
    GROUP BY teacher.teacherid
     ),
     tab_courses AS (
         SELECT DISTINCT name AS courses, t.teacherid FROM lesson
             JOIN course c on lesson.courseid = c.courseid
             RIGHT JOIN teacher t on lesson.teacherid = t.teacherid
     ),
     tab_lessons AS (
         SELECT teacherid, count(lessonid) AS lessons FROM lesson GROUP BY teacherid
     )
SELECT DISTINCT teacher.lastname, teacher.firstname, teacher.middlename,
                category, specialisation, count(courses) AS courses, coalesce(lessons, 0) AS lessons FROM teacher
    JOIN tab_spec ON tab_spec.teacherid = teacher.teacherid
    JOIN tab_courses ON tab_courses.teacherid = teacher.teacherid
    LEFT JOIN tab_lessons ON tab_lessons.teacherid  = teacher.teacherid
GROUP BY teacher.lastname, teacher.firstname, teacher.middlename, category, specialisation, lessons
ORDER BY teacher.lastname, teacher.firstname, teacher.middlename;

-- 3
-- Получить инфу о курсах в виде: название курса, общее кол-во занятий
-- (которые проводились по курсу), общее кол-во разных слушателей курса,
-- кол-во экзаменов по курсу и средняя оценка

WITH tab_lessons AS (
        SELECT DISTINCT name, count(lessonid) AS lessons FROM course
            LEFT JOIN lesson l on course.courseid = l.courseid
        GROUP BY name
     ),
     tab_students AS (
         SELECT DISTINCT studentid, courseid FROM lesson
             JOIN "Group" G on G.number = lesson.number
             JOIN groupstudent g2 on G.number = g2.number
     ),
     exam_pass AS (
         SELECT courseid, count(mark) AS passed FROM exam WHERE mark = 'pass'
         GROUP BY courseid
     ),
     tab_exams AS (
         SELECT count(examid) AS exams, exam.courseid,
                trunc(cast((cast(passed as float4) / cast(count(examid) as float4) * 100) as numeric), 1) || '%' AS passed
                    FROM exam
            JOIN exam_pass ON exam_pass.courseid = exam.courseid
         GROUP BY exam.courseid, passed
     )
SELECT DISTINCT course.name, lessons, count(studentid) AS students, coalesce(exams, 0) AS exams, coalesce(passed, '0.0%') AS passed FROM course
    LEFT JOIN tab_students ON tab_students.courseid = course.courseid
    LEFT JOIN tab_lessons ON tab_lessons.name = course.name
    LEFT JOIN tab_exams ON tab_exams.courseid = course.courseid
GROUP BY course.name, lessons, exams, passed
ORDER BY course.name;

-- 4
-- Оценить использование аудиторий. Отчет в виде: номер аудитории, кол-во мест,
-- общее кол-во курсов (использующих данную аудиторию), кол-во разных групп
-- (занятия для которых проводились в аудитории), кол-во разных преподов (использовавших данную аудиторию)

EXPLAIN ANALYSE WITH tab_groups AS (
    SELECT DISTINCT number, audienceid FROM groupschedule
),
     tab_teacher AS (
         SELECT DISTINCT teacherid, audienceid FROM lesson
             JOIN groupschedule g on lesson.groupschid = g.groupschid
     ),
     tab_courses AS (
         SELECT count(courseid) AS courses, audienceid FROM groupschedule GROUP BY audienceid
     ),
     tab_groups_count AS (
         SELECT count(number) AS groups, tab_groups.audienceid FROM tab_groups
            GROUP BY tab_groups.audienceid
     ),
     tab_teachers_count AS (
         SELECT count(teacherid) AS teachers, audienceid FROM tab_teacher
            GROUP BY tab_teacher.audienceid
     )
SELECT audience.audienceid, places, coalesce(courses, 0) AS courses,
       coalesce(groups, 0) AS groups, coalesce(teachers, 0) AS teachers FROM audience
    LEFT JOIN tab_courses ON tab_courses.audienceid = audience.audienceid
    LEFT JOIN tab_teachers_count ON tab_teachers_count.audienceid = audience.audienceid
    LEFT JOIN tab_groups_count ON tab_groups_count.audienceid = audience.audienceid
ORDER BY audience.audienceid;

EXPLAIN ANALYSE WITH tab_courses AS (
         SELECT count(courseid) AS courses, audienceid FROM groupschedule GROUP BY audienceid
     ),
     tab_groups_count AS (
         SELECT count(distinct number) AS groups, audienceid FROM groupschedule
            GROUP BY audienceid
     ),
     tab_teachers_count AS (
         SELECT count(distinct teacherid) AS teachers, audienceid FROM lesson
         JOIN groupschedule g on lesson.groupschid = g.groupschid
            GROUP BY audienceid
     )
SELECT audience.audienceid, places, coalesce(courses, 0) AS courses,
       coalesce(groups, 0) AS groups, coalesce(teachers, 0) AS teachers FROM audience
    LEFT JOIN tab_courses ON tab_courses.audienceid = audience.audienceid
    LEFT JOIN tab_teachers_count ON tab_teachers_count.audienceid = audience.audienceid
    LEFT JOIN tab_groups_count ON tab_groups_count.audienceid = audience.audienceid
ORDER BY audience.audienceid;

-- 5
-- Найти курсы, пользующиеся повышенным интересом. Мах кол-во слушателей, изучающих данный курс.
-- В виде: название курса, общее кол-во занятий по курсу, общее кол-во слушателей,
-- доход от курса
WITH tab_lessons AS (
         SELECT count(lessonid) AS lessons, courseid FROM lesson
         GROUP BY courseid
),
     tab_students AS (
         SELECT sum(amount) AS amount_sum, courseid FROM groupschedule
             JOIN "Group" G on G.number = groupschedule.number
         GROUP BY courseid
     )
SELECT name, coalesce(lessons, 0) AS lessons,
       coalesce(amount_sum, 0)  AS students, coalesce(cost * amount_sum, 0) AS income FROM course
    LEFT JOIN tab_lessons ON tab_lessons.courseid = course.courseid
    LEFT JOIN tab_students ON tab_students.courseid = course.courseid
ORDER BY income DESC;