CREATE TABLE Teacher (
    TeacherID   SERIAL          NOT NULL    PRIMARY KEY,
    Passport    CHAR(10)        NOT NULL    UNIQUE,
    FirstName   VARCHAR(20)     NOT NULL,
    LastName    VARCHAR(20)     NOT NULL,
    MiddleName  VARCHAR(20),
    Category    SMALLINT        NOT NULL
);

CREATE TABLE Student (
    StudentID   SERIAL          NOT NULL PRIMARY KEY,
    Passport    CHAR(10)        NOT NULL UNIQUE,
    FirstName   VARCHAR(20)     NOT NULL,
    LastName    VARCHAR(20)     NOT NULL,
    MiddleName  VARCHAR(20)
);

CREATE TABLE "Group" (
    Number      SERIAL          NOT NULL PRIMARY KEY,
    TeacherID   INT             NOT NULL REFERENCES Teacher,
    Amount      INT             NOT NULL,
    CHECK ( Amount >= 1 AND Amount <= 15 )
);

CREATE TABLE Course (
    CourseID    SERIAL          NOT NULL PRIMARY KEY ,
    Name        VARCHAR(20)     NOT NULL UNIQUE,
    Cost        DECIMAL(8,2)    NOT NULL CHECK (Cost > 0),
    Days        INT             NOT NULL CHECk (Days > 0)
);

CREATE TABLE InterCourse (
    CourseID    SERIAL          NOT NULL PRIMARY KEY REFERENCES Course
);

CREATE TABLE Certificate (
    CertID      SERIAL          NOT NULL PRIMARY KEY,
    StudentID   INT             NOT NULL REFERENCES Student,
    CourseID    INT             NOT NULL REFERENCES Course,
    Mark        CHAR(4)         CHECK (Mark IN ('fail', 'pass')),
    GotDate     DATE
);

CREATE TABLE SingleCourse (
    CourseID    INT             NOT NULL PRIMARY KEY REFERENCES Course
);

CREATE TABLE CourseComposition (
    PartID      INT             REFERENCES SingleCourse (CourseID),
    GeneralID   INT             REFERENCES InterCourse (CourseID),
    PRIMARY KEY (PartID, GeneralID)
);

CREATE TABLE Audience (
    AudienceID  SERIAL          NOT NULL PRIMARY KEY,
    Places      INT             NOT NULL CHECK ( Places > 0 )
);

CREATE TABLE CoursePayment (
    CPID        SERIAL          NOT NULL PRIMARY KEY,
    StudentID   INT             NOT NULL REFERENCES Student,
    Payment     DECIMAL(8,2)    NOT NULL CHECK ( Payment > 0 ),
    PaymentDate DATE            NOT NULL
);

CREATE TABLE ExamPayment (
    EPID        SERIAL          NOT NULL PRIMARY KEY,
    StudentID   INT             NOT NULL REFERENCES Student,
    Payment     DECIMAL(6,2)    NOT NULL,
    PayDate     DATE            NOT NULL
);

CREATE TABLE Exam (
    ExamID      SERIAL          NOT NULL,
    CourseID    INT             NOT NULL REFERENCES Course,
    EPID        INT             REFERENCES ExamPayment UNIQUE,
    StudentID   INT             NOT NULL REFERENCES Student,
    PRIMARY KEY (ExamID, StudentID, CourseID),
    Try         INT             NOT NULL CHECK ( Try > 0 ),
    Cost        DECIMAL(6,2)    CHECK ( Cost > 0 ),
    Mark        CHAR(4)         NOT NULL CHECK (Mark IN ('fail', 'pass')),
    TryDate     DATE            NOT NULL
);

CREATE TABLE GroupStudent (
    Number      INT             NOT NULL REFERENCES "Group",
    StudentID   INT             NOT NULL REFERENCES Student,
    PRIMARY KEY (Number, StudentID)
);

CREATE TABLE Schedule (
    ScheduleID  SERIAL          NOT NULL PRIMARY KEY,
    StartDate   DATE
);

CREATE TABLE TeacherSpecialisation (
    TeacherID   INT             NOT NULL REFERENCES Teacher,
    CourseID    INT             NOT NULL REFERENCES Course,
    PRIMARY KEY (TeacherID, CourseID)
);

CREATE TABLE CourseSchedule (
    ScheduleID  INT             NOT NULL REFERENCES Schedule (ScheduleID),
    CourseID    INT             NOT NULL REFERENCES Course (CourseID),
    PRIMARY KEY (ScheduleID, CourseID)
);

CREATE TABLE TeacherSchedule (
    TeacherID   INT             NOT NULL REFERENCES Teacher,
    ScheduleID  INT             NOT NULL REFERENCES Schedule,
    PRIMARY KEY (TeacherID, ScheduleID)
);

CREATE TABLE AudienceSpec (
    AudienceID  INT             NOT NULL REFERENCES Audience,
    CourseID    INT             NOT NULL REFERENCES Course,
    PRIMARY KEY (AudienceID, CourseID)
);

CREATE TABLE Holiday (
    HolidayID   SERIAL          NOT NULL PRIMARY KEY,
    HoliDate    DATE            NOT NULL
);

CREATE TABLE TeacherHoliday (
    HolidayID   INT             NOT NULL REFERENCES Holiday,
    TeacherID   INT             NOT NULL REFERENCES Teacher,
    PRIMARY KEY (HolidayID, TeacherID)
);

CREATE TABLE GroupSchedule (
    GroupSchID  SERIAL          NOT NULL PRIMARY KEY,
    Number      INT             NOT NULL REFERENCES "Group" (Number),
    AudienceID  INT             NOT NULL REFERENCES Audience (AudienceID),
    CourseID    INT             NOT NULL,
    ScheduleID  INT             NOT NULL,
    FOREIGN KEY (CourseID, ScheduleID) REFERENCES CourseSchedule (CourseID, ScheduleID),
    UNIQUE (ScheduleID, CourseID, Number)
);

CREATE TABLE Lesson (
    LessonID    SERIAL8         NOT NULL,
    CourseID    INT             NOT NULL REFERENCES Course,
    PRIMARY KEY (LessonID, CourseID),
    GroupSchID  INT             NOT NULL REFERENCES GroupSchedule,
    TeacherID   INT             NOT NULL REFERENCES Teacher,
    Number      INT             NOT NULL REFERENCES "Group",
    DateLesson  DATE            NOT NULL
);