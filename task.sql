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
