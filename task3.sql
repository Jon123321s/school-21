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


