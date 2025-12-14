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
