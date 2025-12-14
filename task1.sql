
part1.sql - Создание базы данных и таблиц



-- 1. Таблица Peers
CREATE TABLE IF NOT EXISTS Peers (
    Nickname VARCHAR PRIMARY KEY,
    Birthday DATE NOT NULL
);

-- 2. Таблица Tasks
CREATE TABLE IF NOT EXISTS Tasks (
    Title VARCHAR PRIMARY KEY,
    ParentTask VARCHAR,
    MaxXP INTEGER NOT NULL CHECK (MaxXP > 0),
    FOREIGN KEY (ParentTask) REFERENCES Tasks(Title)
);

-- 3. Таблица Checks
CREATE TABLE IF NOT EXISTS Checks (
    ID INTEGER PRIMARY KEY AUTOINCREMENT,
    Peer VARCHAR NOT NULL,
    Task VARCHAR NOT NULL,
    Date DATE NOT NULL,
    FOREIGN KEY (Peer) REFERENCES Peers(Nickname),
    FOREIGN KEY (Task) REFERENCES Tasks(Title)
);

-- 4. Таблица P2P
CREATE TABLE IF NOT EXISTS P2P (
    ID INTEGER PRIMARY KEY AUTOINCREMENT,
    CheckID INTEGER NOT NULL,
    CheckingPeer VARCHAR NOT NULL,
    State VARCHAR NOT NULL CHECK (State IN ('Start', 'Success', 'Failure')),
    Time TIME NOT NULL,
    FOREIGN KEY (CheckID) REFERENCES Checks(ID) ON DELETE CASCADE,
    FOREIGN KEY (CheckingPeer) REFERENCES Peers(Nickname)
);

-- 5. Таблица Verter
CREATE TABLE IF NOT EXISTS Verter (
    ID INTEGER PRIMARY KEY AUTOINCREMENT,
    CheckID INTEGER NOT NULL,
    State VARCHAR NOT NULL CHECK (State IN ('Start', 'Success', 'Failure')),
    Time TIME NOT NULL,
    FOREIGN KEY (CheckID) REFERENCES Checks(ID) ON DELETE CASCADE
);

-- 6. Таблица TransferredPoints
CREATE TABLE IF NOT EXISTS TransferredPoints (
    ID INTEGER PRIMARY KEY AUTOINCREMENT,
    CheckingPeer VARCHAR NOT NULL,
    CheckedPeer VARCHAR NOT NULL,
    PointsAmount INTEGER NOT NULL DEFAULT 1 CHECK (PointsAmount >= 0),
    FOREIGN KEY (CheckingPeer) REFERENCES Peers(Nickname),
    FOREIGN KEY (CheckedPeer) REFERENCES Peers(Nickname)
);

-- 7. Таблица Friends
CREATE TABLE IF NOT EXISTS Friends (
    ID INTEGER PRIMARY KEY AUTOINCREMENT,
    Peer1 VARCHAR NOT NULL,
    Peer2 VARCHAR NOT NULL,
    FOREIGN KEY (Peer1) REFERENCES Peers(Nickname),
    FOREIGN KEY (Peer2) REFERENCES Peers(Nickname),
    CHECK (Peer1 <> Peer2)
);

-- 8. Таблица Recommendations
CREATE TABLE IF NOT EXISTS Recommendations (
    ID INTEGER PRIMARY KEY AUTOINCREMENT,
    Peer VARCHAR NOT NULL,
    RecommendedPeer VARCHAR NOT NULL,
    FOREIGN KEY (Peer) REFERENCES Peers(Nickname),
    FOREIGN KEY (RecommendedPeer) REFERENCES Peers(Nickname),
    CHECK (Peer <> RecommendedPeer)
);

-- 9. Таблица XP
CREATE TABLE IF NOT EXISTS XP (
    ID INTEGER PRIMARY KEY AUTOINCREMENT,
    CheckID INTEGER NOT NULL,
    XPAmount INTEGER NOT NULL CHECK (XPAmount > 0),
    FOREIGN KEY (CheckID) REFERENCES Checks(ID) ON DELETE CASCADE
);

-- 10. Таблица TimeTracking
CREATE TABLE IF NOT EXISTS TimeTracking (
    ID INTEGER PRIMARY KEY AUTOINCREMENT,
    Peer VARCHAR NOT NULL,
    Date DATE NOT NULL,
    Time TIME NOT NULL,
    State INTEGER NOT NULL CHECK (State IN (1, 2)),
    FOREIGN KEY (Peer) REFERENCES Peers(Nickname)
);

-- Индексы для оптимизации
CREATE INDEX IF NOT EXISTS idx_checks_peer ON Checks(Peer);
CREATE INDEX IF NOT EXISTS idx_checks_task ON Checks(Task);
CREATE INDEX IF NOT EXISTS idx_p2p_checkid ON P2P(CheckID);
CREATE INDEX IF NOT EXISTS idx_verter_checkid ON Verter(CheckID);
CREATE INDEX IF NOT EXISTS idx_xp_checkid ON XP(CheckID);
CREATE INDEX IF NOT EXISTS idx_timetracking_peer_date ON TimeTracking(Peer, Date);

-- Тестовые данные
INSERT OR IGNORE INTO Peers (Nickname, Birthday) VALUES
('john', '1995-03-15'),
('mary', '1996-07-22'),
('bob', '1997-11-30'),
('alice', '1998-05-10'),
('charlie', '1999-09-05'),
('diana', '2000-01-12'),
('eve', '2001-03-25'),
('frank', '2002-08-08');

INSERT OR IGNORE INTO Tasks (Title, ParentTask, MaxXP) VALUES
('C2_SimpleBashUtils', NULL, 250),
('C3_s21_string+', 'C2_SimpleBashUtils', 500),
('C4_s21_math', 'C2_SimpleBashUtils', 300),
('C5_s21_decimal', 'C4_s21_math', 350),
('C6_s21_matrix', 'C5_s21_decimal', 200),
('C7_SmartCalc_v1.0', 'C3_s21_string+', 600),
('CPP1_s21_matrix+', 'C6_s21_matrix', 400);

INSERT OR IGNORE INTO Checks (Peer, Task, Date) VALUES
('john', 'C2_SimpleBashUtils', '2024-01-10'),
('mary', 'C2_SimpleBashUtils', '2024-01-11'),
('bob', 'C3_s21_string+', '2024-01-12'),
('alice', 'C4_s21_math', '2024-01-13'),
('charlie', 'C5_s21_decimal', '2024-01-14'),
('diana', 'C6_s21_matrix', '2024-01-15'),
('eve', 'C7_SmartCalc_v1.0', '2024-01-16');

INSERT OR IGNORE INTO P2P (CheckID, CheckingPeer, State, Time) VALUES
(1, 'mary', 'Start', '10:00:00'),
(1, 'mary', 'Success', '10:30:00'),
(2, 'john', 'Start', '11:00:00'),
(2, 'john', 'Success', '11:45:00'),
(3, 'alice', 'Start', '14:00:00'),
(3, 'alice', 'Success', '15:00:00'),
(4, 'bob', 'Start', '16:00:00'),
(4, 'bob', 'Success', '16:30:00'),
(5, 'diana', 'Start', '09:00:00'),
(5, 'diana', 'Success', '10:00:00'),
(6, 'eve', 'Start', '13:00:00'),
(6, 'eve', 'Success', '14:30:00');

INSERT OR IGNORE INTO Verter (CheckID, State, Time) VALUES
(1, 'Start', '10:35:00'),
(1, 'Success', '10:40:00'),
(2, 'Start', '11:50:00'),
(2, 'Success', '11:55:00'),
(3, 'Start', '15:05:00'),
(3, 'Success', '15:10:00');

INSERT OR IGNORE INTO TransferredPoints (CheckingPeer, CheckedPeer, PointsAmount) VALUES
('mary', 'john', 1),
('john', 'mary', 1),
('alice', 'bob', 1),
('bob', 'alice', 1),
('diana', 'charlie', 1),
('eve', 'diana', 1),
('frank', 'eve', 2),
('john', 'bob', 1);

INSERT OR IGNORE INTO Friends (Peer1, Peer2) VALUES
('john', 'mary'),
('john', 'bob'),
('mary', 'alice'),
('bob', 'charlie'),
('diana', 'eve'),
('eve', 'frank');

INSERT OR IGNORE INTO Recommendations (Peer, RecommendedPeer) VALUES
('john', 'mary'),
('john', 'bob'),
('mary', 'john'),
('bob', 'alice'),
('alice', 'charlie'),
('charlie', 'diana'),
('diana', 'eve'),
('eve', 'frank');

INSERT OR IGNORE INTO XP (CheckID, XPAmount) VALUES
(1, 250),
(2, 250),
(3, 500),
(4, 300);

INSERT OR IGNORE INTO TimeTracking (Peer, Date, Time, State) VALUES
('john', '2024-01-10', '09:00:00', 1),
('john', '2024-01-10', '18:00:00', 2),
('john', '2024-01-10', '19:00:00', 1),
('john', '2024-01-10', '23:00:00', 2),
('mary', '2024-01-11', '09:30:00', 1),
('mary', '2024-01-11', '20:30:00', 2),
('bob', '2024-01-12', '10:00:00', 1),
('bob', '2024-01-12', '19:00:00', 2),
('alice', '2024-01-13', '08:45:00', 1),
('alice', '2024-01-13', '17:30:00', 2),
('charlie', '2024-01-14', '10:15:00', 1),
('charlie', '2024-01-14', '21:45:00', 2);


part2.sql - Изменение данных 



-- 1. Триггер для обновления TransferredPoints при начале P2P проверки
CREATE TRIGGER IF NOT EXISTS trg_update_transferred_points
AFTER INSERT ON P2P
FOR EACH ROW
WHEN NEW.State = 'Start'
BEGIN
    INSERT OR REPLACE INTO TransferredPoints (CheckingPeer, CheckedPeer, PointsAmount)
    SELECT 
        NEW.CheckingPeer,
        c.Peer,
        COALESCE(
            (SELECT PointsAmount + 1 
             FROM TransferredPoints 
             WHERE CheckingPeer = NEW.CheckingPeer
               AND CheckedPeer = c.Peer),
            1
        )
    FROM Checks c
    WHERE c.ID = NEW.CheckID;
END;

-- 2. Триггер для автоматического создания Verter проверки после успешной P2P
CREATE TRIGGER IF NOT EXISTS trg_add_verter_check
AFTER UPDATE ON P2P
FOR EACH ROW
WHEN NEW.State = 'Success' AND OLD.State != 'Success'
BEGIN
    INSERT INTO Verter (CheckID, State, Time)
    VALUES (NEW.CheckID, 'Start', time('now'));
END;

-- 3. Триггер для добавления XP после успешной Verter проверки
CREATE TRIGGER IF NOT EXISTS trg_add_xp_after_verter
AFTER UPDATE ON Verter
FOR EACH ROW
WHEN NEW.State = 'Success' AND OLD.State = 'Start'
BEGIN
    INSERT INTO XP (CheckID, XPAmount)
    SELECT NEW.CheckID, t.MaxXP
    FROM Checks c
    JOIN Tasks t ON c.Task = t.Title
    WHERE c.ID = NEW.CheckID;
END;

-- 4. Триггер для проверки валидности XP перед вставкой
CREATE TRIGGER IF NOT EXISTS trg_validate_xp
BEFORE INSERT ON XP
FOR EACH ROW
BEGIN
    -- Проверяем, что проверка существует и успешна
    DECLARE check_exists INTEGER;
    DECLARE p2p_success INTEGER;
    DECLARE max_xp_value INTEGER;
    DECLARE has_verter INTEGER;
    DECLARE verter_success INTEGER;
    
    -- Проверяем существование проверки
    SELECT COUNT(*) INTO check_exists FROM Checks WHERE ID = NEW.CheckID;
    
    IF check_exists = 0 THEN
        SELECT RAISE(ABORT, 'Check does not exist');
    END IF;
    
    -- Проверяем успешность P2P
    SELECT COUNT(*) INTO p2p_success 
    FROM P2P 
    WHERE CheckID = NEW.CheckID AND State = 'Success';
    
    IF p2p_success = 0 THEN
        SELECT RAISE(ABORT, 'Cannot add XP: P2P check was not successful');
    END IF;
    
    -- Проверяем наличие Verter проверки
    SELECT COUNT(*) INTO has_verter 
    FROM Verter 
    WHERE CheckID = NEW.CheckID;
    
    -- Если есть Verter проверка, проверяем ее успешность
    IF has_verter > 0 THEN
        SELECT COUNT(*) INTO verter_success 
        FROM Verter 
        WHERE CheckID = NEW.CheckID AND State = 'Success';
        
        IF verter_success = 0 THEN
            SELECT RAISE(ABORT, 'Cannot add XP: Verter check was not successful');
        END IF;
    END IF;
    
    -- Проверяем, что XP не превышает максимум
    SELECT t.MaxXP INTO max_xp_value
    FROM Checks c
    JOIN Tasks t ON c.Task = t.Title
    WHERE c.ID = NEW.CheckID;
    
    IF NEW.XPAmount > max_xp_value THEN
        SELECT RAISE(ABORT, 'XP amount ' || NEW.XPAmount || ' exceeds maximum ' || max_xp_value);
    END IF;
END;

-- 5. Триггер для логирования изменений в P2P
CREATE TABLE IF NOT EXISTS P2PLog (
    ID INTEGER PRIMARY KEY AUTOINCREMENT,
    CheckID INTEGER,
    CheckingPeer VARCHAR,
    OldState VARCHAR,
    NewState VARCHAR,
    ChangeTime DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER IF NOT EXISTS trg_log_p2p_changes
AFTER UPDATE ON P2P
FOR EACH ROW
BEGIN
    INSERT INTO P2PLog (CheckID, CheckingPeer, OldState, NewState)
    VALUES (NEW.CheckID, NEW.CheckingPeer, OLD.State, NEW.State);
END;

-- 6. Процедуры для ручного добавления проверок (через триггеры и представления)
-- Создаем таблицу для хранения запросов на проверку
CREATE TABLE IF NOT EXISTS CheckRequests (
    ID INTEGER PRIMARY KEY AUTOINCREMENT,
    Peer VARCHAR NOT NULL,
    Task VARCHAR NOT NULL,
    RequestTime DATETIME DEFAULT CURRENT_TIMESTAMP,
    Status VARCHAR DEFAULT 'Pending',
    FOREIGN KEY (Peer) REFERENCES Peers(Nickname),
    FOREIGN KEY (Task) REFERENCES Tasks(Title)
);

-- Триггер для автоматического создания проверки при подтверждении запроса
CREATE TRIGGER IF NOT EXISTS trg_create_check_from_request
AFTER UPDATE ON CheckRequests
FOR EACH ROW
WHEN NEW.Status = 'Approved' AND OLD.Status = 'Pending'
BEGIN
    INSERT INTO Checks (Peer, Task, Date)
    VALUES (NEW.Peer, NEW.Task, date('now'));
END;



part3.sql - Получение данных 




-- 1. Получить читаемое представление TransferredPoints
SELECT 
    tp.CheckingPeer AS "Проверяющий пир",
    tp.CheckedPeer AS "Проверяемый пир",
    tp.PointsAmount AS "Количество передач",
    CASE 
        WHEN tp.PointsAmount = 1 THEN 'Одна проверка'
        WHEN tp.PointsAmount BETWEEN 2 AND 5 THEN 'Несколько проверок'
        ELSE 'Много проверок'
    END AS "Статус"
FROM TransferredPoints tp
ORDER BY tp.PointsAmount DESC, tp.CheckingPeer;

-- 2. Получить информацию о проверках и полученном XP
SELECT 
    c.Peer AS "Пир",
    c.Task AS "Задание",
    COALESCE(x.XPAmount, 0) AS "Получено XP",
    t.MaxXP AS "Максимальный XP",
    CASE 
        WHEN x.XPAmount IS NULL THEN '❌ Не завершено'
        WHEN x.XPAmount = t.MaxXP THEN '✅ Завершено на 100%'
        ELSE '⚠️  Завершено частично (' || ROUND((x.XPAmount * 100.0 / t.MaxXP), 1) || '%)'
    END AS "Статус выполнения"
FROM Checks c
JOIN Tasks t ON c.Task = t.Title
LEFT JOIN XP x ON c.ID = x.CheckID
ORDER BY c.Peer, c.Date;

-- 3. Найти пиров, которые не покидали кампус весь день
WITH DailyVisits AS (
    SELECT 
        Peer,
        Date,
        COUNT(*) AS VisitCount,
        MIN(Time) AS FirstEntry,
        MAX(Time) AS LastExit
    FROM TimeTracking
    GROUP BY Peer, Date
    HAVING COUNT(*) >= 2
)
SELECT 
    dv.Peer AS "Пир",
    dv.Date AS "Дата",
    dv.FirstEntry AS "Первое появление",
    dv.LastExit AS "Последний выход",
    CASE 
        WHEN time(dv.LastExit) >= '20:00:00' THEN '✅ Весь день в кампусе'
        ELSE '⚠️  Ушел раньше 20:00'
    END AS "Статус дня"
FROM DailyVisits dv
WHERE time(dv.LastExit) >= '20:00:00'
ORDER BY dv.Date DESC, dv.Peer;

-- 4. Рассчитать изменение количества баллов каждого пира
WITH ReceivedPoints AS (
    SELECT 
        CheckedPeer AS Peer,
        SUM(PointsAmount) AS Received
    FROM TransferredPoints
    GROUP BY CheckedPeer
),
GivenPoints AS (
    SELECT 
        CheckingPeer AS Peer,
        SUM(PointsAmount) AS Given
    FROM TransferredPoints
    GROUP BY CheckingPeer
)
SELECT 
    COALESCE(r.Peer, g.Peer) AS "Пир",
    COALESCE(r.Received, 0) AS "Получено баллов",
    COALESCE(g.Given, 0) AS "Отдано баллов",
    COALESCE(r.Received, 0) - COALESCE(g.Given, 0) AS "Баланс",
    CASE 
        WHEN COALESCE(r.Received, 0) - COALESCE(g.Given, 0) > 0 THEN '📈 В плюсе'
        WHEN COALESCE(r.Received, 0) - COALESCE(g.Given, 0) < 0 THEN '📉 В минусе'
        ELSE '➖ Нейтрально'
    END AS "Статус"
FROM ReceivedPoints r
FULL OUTER JOIN GivenPoints g ON r.Peer = g.Peer
ORDER BY "Баланс" DESC;

-- 5. Найти самых рекомендуемых пиров
SELECT 
    r.RecommendedPeer AS "Рекомендуемый пир",
    COUNT(*) AS "Количество рекомендаций",
    GROUP_CONCAT(DISTINCT r.Peer, ', ') AS "Рекомендовали"
FROM Recommendations r
GROUP BY r.RecommendedPeer
ORDER BY COUNT(*) DESC
LIMIT 10;

-- 6. Получить статистику по заданиям
SELECT 
    t.Title AS "Задание",
    COUNT(DISTINCT c.ID) AS "Всего проверок",
    COUNT(DISTINCT x.CheckID) AS "Успешных проверок",
    ROUND(
        COUNT(DISTINCT x.CheckID) * 100.0 / 
        NULLIF(COUNT(DISTINCT c.ID), 0), 
        2
    ) AS "Процент успеха",
    AVG(COALESCE(x.XPAmount, 0)) AS "Средний XP",
    t.MaxXP AS "Максимальный XP"
FROM Tasks t
LEFT JOIN Checks c ON t.Title = c.Task
LEFT JOIN XP x ON c.ID = x.CheckID
GROUP BY t.Title, t.MaxXP
ORDER BY "Процент успеха" DESC;

-- 7. Найти пиров, выполнивших наибольшее количество заданий
SELECT 
    c.Peer AS "Пир",
    COUNT(DISTINCT c.Task) AS "Выполнено заданий",
    SUM(COALESCE(x.XPAmount, 0)) AS "Всего XP",
    GROUP_CONCAT(DISTINCT c.Task, ', ') AS "Список заданий"
FROM Checks c
LEFT JOIN XP x ON c.ID = x.CheckID
WHERE x.CheckID IS NOT NULL
GROUP BY c.Peer
ORDER BY "Выполнено заданий" DESC, "Всего XP" DESC;

-- 8. Найти друзей, которые проверяли друг друга
SELECT 
    f.Peer1 AS "Пир 1",
    f.Peer2 AS "Пир 2",
    COUNT(DISTINCT p1.CheckID) AS "Пир1 проверял Пир2",
    COUNT(DISTINCT p2.CheckID) AS "Пир2 проверял Пир1",
    CASE 
        WHEN COUNT(DISTINCT p1.CheckID) > 0 AND COUNT(DISTINCT p2.CheckID) > 0 
        THEN '✅ Взаимные проверки'
        WHEN COUNT(DISTINCT p1.CheckID) > 0 
        THEN '→ Пир1 проверял Пир2'
        WHEN COUNT(DISTINCT p2.CheckID) > 0 
        THEN '← Пир2 проверял Пир1'
        ELSE '❌ Нет проверок'
    END AS "Статус проверок"
FROM Friends f
LEFT JOIN P2P p1 ON f.Peer1 = p1.CheckingPeer 
    AND EXISTS (SELECT 1 FROM Checks c WHERE c.ID = p1.CheckID AND c.Peer = f.Peer2)
LEFT JOIN P2P p2 ON f.Peer2 = p2.CheckingPeer 
    AND EXISTS (SELECT 1 FROM Checks c WHERE c.ID = p2.CheckID AND c.Peer = f.Peer1)
GROUP BY f.Peer1, f.Peer2;

-- 9. Найти самых активных пиров по посещениям
SELECT 
    tt.Peer AS "Пир",
    COUNT(DISTINCT tt.Date) AS "Дней в кампусе",
    COUNT(*) AS "Всего входов/выходов",
    AVG(
        (SELECT COUNT(*) 
         FROM TimeTracking tt2 
         WHERE tt2.Peer = tt.Peer AND tt2.Date = tt.Date)
    ) AS "Среднее действий в день",
    MIN(tt.Date) AS "Первое посещение",
    MAX(tt.Date) AS "Последнее посещение"
FROM TimeTracking tt
GROUP BY tt.Peer
ORDER BY "Дней в кампусе" DESC, "Всего входов/выходов" DESC;

-- 10. Получить прогресс каждого пира по заданиям
SELECT 
    p.Nickname AS "Пир",
    COALESCE(completed_tasks.TaskCount, 0) AS "Выполнено заданий",
    COALESCE(completed_tasks.TotalXP, 0) AS "Всего XP",
    COALESCE(current_task.CurrentTask, 'Нет активных') AS "Текущее задание",
    COALESCE(recommendations.Recommendations, 'Нет рекомендаций') AS "Рекомендации"
FROM Peers p
LEFT JOIN (
    SELECT 
        c.Peer,
        COUNT(DISTINCT c.Task) AS TaskCount,
        SUM(x.XPAmount) AS TotalXP
    FROM Checks c
    JOIN XP x ON c.ID = x.CheckID
    GROUP BY c.Peer
) completed_tasks ON p.Nickname = completed_tasks.Peer
LEFT JOIN (
    SELECT 
        c.Peer,
        c.Task AS CurrentTask
    FROM Checks c
    WHERE NOT EXISTS (
        SELECT 1 FROM XP x WHERE x.CheckID = c.ID
    )
    ORDER BY c.Date DESC
    LIMIT 1
) current_task ON p.Nickname = current_task.Peer
LEFT JOIN (
    SELECT 
        r.RecommendedPeer AS Peer,
        GROUP_CONCAT(r.Peer || ' → ' || r.RecommendedPeer, ', ') AS Recommendations
    FROM Recommendations r
    GROUP BY r.RecommendedPeer
) recommendations ON p.Nickname = recommendations.Peer
ORDER BY completed_tasks.TotalXP DESC NULLS LAST;







part4.sql - Метаданные


-- 1. Создаем временную базу для тестирования (в SQLite используем отдельные таблицы)
CREATE TABLE IF NOT EXISTS metadata_test (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    test_name VARCHAR NOT NULL,
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 2. Процедура для получения списка всех таблиц
CREATE VIEW IF NOT EXISTS vw_all_tables AS
SELECT 
    'TABLE' AS object_type,
    name AS object_name,
    'N/A' AS parameters,
    'Created in SQLite schema' AS description
FROM sqlite_master 
WHERE type = 'table' 
  AND name NOT LIKE 'sqlite_%'
ORDER BY name;

-- 3. Процедура для получения списка всех индексов
CREATE VIEW IF NOT EXISTS vw_all_indexes AS
SELECT 
    'INDEX' AS object_type,
    name AS object_name,
    tbl_name AS parent_table,
    sql AS definition
FROM sqlite_master 
WHERE type = 'index'
  AND name NOT LIKE 'sqlite_%'
ORDER BY tbl_name, name;

-- 4. Процедура для получения списка всех триггеров
CREATE VIEW IF NOT EXISTS vw_all_triggers AS
SELECT 
    'TRIGGER' AS object_type,
    name AS object_name,
    tbl_name AS parent_table,
    sql AS definition
FROM sqlite_master 
WHERE type = 'trigger'
ORDER BY tbl_name, name;

-- 5. Процедура для получения информации о столбцах таблицы
CREATE VIEW IF NOT EXISTS vw_table_columns AS
SELECT 
    m.name AS table_name,
    p.name AS column_name,
    p.type AS data_type,
    CASE WHEN p."notnull" = 1 THEN 'NOT NULL' ELSE 'NULL' END AS nullable,
    CASE WHEN p.pk = 1 THEN 'PRIMARY KEY' ELSE '' END AS is_primary
FROM sqlite_master m
JOIN pragma_table_info(m.name) p
WHERE m.type = 'table'
  AND m.name NOT LIKE 'sqlite_%'
ORDER BY m.name, p.cid;

-- 6. Процедура для получения внешних ключей
CREATE VIEW IF NOT EXISTS vw_foreign_keys AS
SELECT 
    m.name AS table_name,
    f."from" AS column_name,
    f."table" AS referenced_table,
    f."to" AS referenced_column
FROM sqlite_master m
JOIN pragma_foreign_key_list(m.name) f
WHERE m.type = 'table'
  AND m.name NOT LIKE 'sqlite_%'
ORDER BY m.name, f.id;

-- 7. Процедура для поиска объектов по строке
CREATE VIEW IF NOT EXISTS vw_search_objects AS
SELECT 
    type AS object_type,
    name AS object_name,
    CASE 
        WHEN type = 'table' THEN 'Table: ' || name
        WHEN type = 'index' THEN 'Index for table: ' || tbl_name
        WHEN type = 'trigger' THEN 'Trigger for table: ' || tbl_name
        WHEN type = 'view' THEN 'View: ' || name
        ELSE type || ': ' || name
    END AS description,
    sql AS full_definition
FROM sqlite_master 
WHERE name NOT LIKE 'sqlite_%'
  AND (name LIKE '%check%' OR sql LIKE '%check%' OR tbl_name LIKE '%check%')
ORDER BY type, name;

-- 8. Статистика базы данных
CREATE VIEW IF NOT EXISTS vw_database_stats AS
WITH TableStats AS (
    SELECT 
        'Tables' AS category,
        COUNT(*) AS count,
        GROUP_CONCAT(name, ', ') AS details
    FROM sqlite_master 
    WHERE type = 'table' AND name NOT LIKE 'sqlite_%'
),
IndexStats AS (
    SELECT 
        'Indexes' AS category,
        COUNT(*) AS count,
        GROUP_CONCAT(name, ', ') AS details
    FROM sqlite_master 
    WHERE type = 'index' AND name NOT LIKE 'sqlite_%'
),
TriggerStats AS (
    SELECT 
        'Triggers' AS category,
        COUNT(*) AS count,
        GROUP_CONCAT(name, ', ') AS details
    FROM sqlite_master 
    WHERE type = 'trigger'
),
RowStats AS (
    SELECT 
        'Total Rows' AS category,
        SUM(row_count) AS count,
        'All tables combined' AS details
    FROM (
        SELECT COUNT(*) AS row_count FROM Peers
        UNION ALL SELECT COUNT(*) FROM Tasks
        UNION ALL SELECT COUNT(*) FROM Checks
        UNION ALL SELECT COUNT(*) FROM P2P
        UNION ALL SELECT COUNT(*) FROM Verter
        UNION ALL SELECT COUNT(*) FROM TransferredPoints
        UNION ALL SELECT COUNT(*) FROM Friends
        UNION ALL SELECT COUNT(*) FROM Recommendations
        UNION ALL SELECT COUNT(*) FROM XP
        UNION ALL SELECT COUNT(*) FROM TimeTracking
    )
)
SELECT * FROM TableStats
UNION ALL SELECT * FROM IndexStats
UNION ALL SELECT * FROM TriggerStats
UNION ALL SELECT * FROM RowStats;

-- 9. Процедура для получения размера таблиц (приблизительно)
CREATE VIEW IF NOT EXISTS vw_table_sizes AS
SELECT 
    m.name AS table_name,
    (SELECT COUNT(*) FROM Peers) AS peers_count,
    (SELECT COUNT(*) FROM Checks) AS checks_count,
    (SELECT COUNT(*) FROM P2P) AS p2p_count,
    (SELECT COUNT(*) FROM XP) AS xp_count,
    (SELECT COUNT(*) FROM TimeTracking) AS timetracking_count
FROM sqlite_master m
WHERE m.type = 'table' 
  AND m.name IN ('Peers', 'Checks', 'P2P', 'XP', 'TimeTracking')
GROUP BY m.name;

-- 10. Информация о связях между таблицами
CREATE VIEW IF NOT EXISTS vw_table_relationships AS
SELECT 
    'Peers' AS source_table,
    'Nickname' AS source_column,
    'Checks' AS target_table,
    'Peer' AS target_column,
    'Peer → Check' AS relationship
UNION ALL
SELECT 'Tasks', 'Title', 'Checks', 'Task', 'Task → Check'
UNION ALL
SELECT 'Checks', 'ID', 'P2P', 'CheckID', 'Check → P2P'
UNION ALL
SELECT 'Peers', 'Nickname', 'P2P', 'CheckingPeer', 'Peer → P2P Checking'
UNION ALL
SELECT 'Checks', 'ID', 'Verter', 'CheckID', 'Check → Verter'
UNION ALL
SELECT 'Checks', 'ID', 'XP', 'CheckID', 'Check → XP'
UNION ALL
SELECT 'Peers', 'Nickname', 'Friends', 'Peer1', 'Peer → Friend (1)'
UNION ALL
SELECT 'Peers', 'Nickname', 'Friends', 'Peer2', 'Peer → Friend (2)'
UNION ALL
SELECT 'Peers', 'Nickname', 'TimeTracking', 'Peer', 'Peer → TimeTracking'
ORDER BY source_table, target_table;

-- 11. Примеры использования метаданных
-- Показать все таблицы
SELECT * FROM vw_all_tables;

-- Показать все триггеры
SELECT * FROM vw_all_triggers;

-- Показать структуру таблицы Checks
SELECT * FROM vw_table_columns WHERE table_name = 'Checks';

-- Показать статистику базы данных
SELECT * FROM vw_database_stats;

-- Показать внешние ключи
SELECT * FROM vw_foreign_keys;

-- Поиск объектов содержащих "check"
SELECT * FROM vw_search_objects;

-- 12. Утилита для очистки тестовых данных (безопасная)
CREATE VIEW IF NOT EXISTS vw_safe_cleanup AS
SELECT 
    'DELETE FROM ' || name || ' WHERE 1=1;' AS cleanup_statement,
    'Table: ' || name AS description,
    '⚠️ WARNING: This will delete all data from ' || name AS warning
FROM sqlite_master 
WHERE type = 'table' 
  AND name NOT LIKE 'sqlite_%'
  AND name NOT IN ('metadata_test', 'P2PLog', 'CheckRequests')
ORDER BY name;

-- 13. Информация о последних изменениях
CREATE TABLE IF NOT EXISTS metadata_changes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    change_type VARCHAR NOT NULL,
    object_name VARCHAR,
    change_details TEXT,
    changed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR DEFAULT 'system'
);

-- Триггер для отслеживания создания таблиц
CREATE TRIGGER IF NOT EXISTS trg_log_table_creation
AFTER CREATE ON database
BEGIN
    INSERT INTO metadata_changes (change_type, object_name, change_details)
    VALUES ('TABLE_CREATED', 'unknown', 'Table created: ' || NEW.name);
END;
