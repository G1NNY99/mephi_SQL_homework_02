
/*
ФИО: Дианов Егор Романович
Вариант: 6 (дата рождения 05.05.1999; 5 % 26 + 1 = 6)
Условия ДЗ: Заполнить таблицы минимум пятью осмысленными записями.

Задание 1: Выбрать станции, на которых поезда останавливаются с 14:00 до 15:00,
отсортировать по идентификатору станции по возрастанию и времени прибытия по убыванию.

Задание 2: Сопоставить дням недели количество поездов,
останавливающихся на станции «Москворечье».
*/

BEGIN;

CREATE SCHEMA IF NOT EXISTS railway_hw1;

DROP TABLE IF EXISTS railway_hw1.route_exceptions;
DROP TABLE IF EXISTS railway_hw1.route_weekdays;
DROP TABLE IF EXISTS railway_hw1.route_stations;
DROP TABLE IF EXISTS railway_hw1.station_connections;
DROP TABLE IF EXISTS railway_hw1.train_routes;
DROP TABLE IF EXISTS railway_hw1.ticket_prices;
DROP TABLE IF EXISTS railway_hw1.stations;

CREATE TABLE railway_hw1.stations (
    station_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    station_name VARCHAR(150) NOT NULL,
    tariff_zone SMALLINT NOT NULL,
    direction_order INTEGER NOT NULL,
    distance_km NUMERIC(8, 2),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT stations_name_not_blank_chk CHECK (BTRIM(station_name) <> ''),
    CONSTRAINT stations_tariff_zone_chk CHECK (tariff_zone >= 0),
    CONSTRAINT stations_direction_order_chk CHECK (direction_order >= 1),
    CONSTRAINT stations_distance_chk CHECK (distance_km >= 0)
);

CREATE TABLE railway_hw1.station_connections (
    from_station_id BIGINT NOT NULL,
    to_station_id BIGINT NOT NULL,
    distance_km NUMERIC(8, 2),
    CONSTRAINT station_connections_pk PRIMARY KEY (from_station_id, to_station_id),
    CONSTRAINT station_connections_from_fk FOREIGN KEY (from_station_id)
        REFERENCES railway_hw1.stations (station_id) ON DELETE RESTRICT,
    CONSTRAINT station_connections_to_fk FOREIGN KEY (to_station_id)
        REFERENCES railway_hw1.stations (station_id) ON DELETE RESTRICT,
    CONSTRAINT station_connections_distinct_chk CHECK (from_station_id <> to_station_id),
    CONSTRAINT station_connections_distance_chk CHECK (distance_km > 0)
);

CREATE TABLE railway_hw1.train_routes (
    route_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    route_number VARCHAR(20) NOT NULL,
    start_station_id BIGINT NOT NULL,
    end_station_id BIGINT NOT NULL,
    route_name VARCHAR(150),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT train_routes_number_uk UNIQUE (route_number),
    CONSTRAINT train_routes_number_not_blank_chk CHECK (BTRIM(route_number) <> ''),
    CONSTRAINT train_routes_name_not_blank_chk CHECK (route_name IS NULL OR BTRIM(route_name) <> ''),
    CONSTRAINT train_routes_stations_distinct_chk CHECK (start_station_id <> end_station_id),
    CONSTRAINT train_routes_start_fk FOREIGN KEY (start_station_id)
        REFERENCES railway_hw1.stations (station_id) ON DELETE RESTRICT,
    CONSTRAINT train_routes_end_fk FOREIGN KEY (end_station_id)
        REFERENCES railway_hw1.stations (station_id) ON DELETE RESTRICT
);

CREATE TABLE railway_hw1.route_stations (
    route_id BIGINT NOT NULL,
    sequence_number INTEGER NOT NULL,
    station_id BIGINT NOT NULL,
    is_stop BOOLEAN NOT NULL DEFAULT TRUE,
    arrival_time TIME,
    departure_time TIME,
    arrival_day_offset SMALLINT NOT NULL DEFAULT 0,
    departure_day_offset SMALLINT NOT NULL DEFAULT 0,
    CONSTRAINT route_stations_pk PRIMARY KEY (route_id, sequence_number),
    CONSTRAINT route_stations_route_station_uk UNIQUE (route_id, station_id),
    CONSTRAINT route_stations_route_fk FOREIGN KEY (route_id)
        REFERENCES railway_hw1.train_routes (route_id) ON DELETE CASCADE,
    CONSTRAINT route_stations_station_fk FOREIGN KEY (station_id)
        REFERENCES railway_hw1.stations (station_id) ON DELETE RESTRICT,
    CONSTRAINT route_stations_sequence_chk CHECK (sequence_number >= 1),
    CONSTRAINT route_stations_arrival_offset_chk CHECK (arrival_day_offset >= 0),
    CONSTRAINT route_stations_departure_offset_chk CHECK (departure_day_offset >= 0),
    CONSTRAINT route_stations_stop_times_chk CHECK (
        (is_stop AND (arrival_time IS NOT NULL OR departure_time IS NOT NULL))
        OR (NOT is_stop AND arrival_time IS NULL AND departure_time IS NULL)
    ),
    CONSTRAINT route_stations_unused_offsets_chk CHECK (
        (arrival_time IS NOT NULL OR arrival_day_offset = 0)
        AND (departure_time IS NOT NULL OR departure_day_offset = 0)
    ),
    CONSTRAINT route_stations_time_order_chk CHECK (
        arrival_time IS NULL
        OR departure_time IS NULL
        OR departure_day_offset > arrival_day_offset
        OR (departure_day_offset = arrival_day_offset AND departure_time >= arrival_time)
    )
);

CREATE TABLE railway_hw1.route_weekdays (
    route_id BIGINT NOT NULL,
    day_of_week SMALLINT NOT NULL,
    CONSTRAINT route_weekdays_pk PRIMARY KEY (route_id, day_of_week),
    CONSTRAINT route_weekdays_route_fk FOREIGN KEY (route_id)
        REFERENCES railway_hw1.train_routes (route_id) ON DELETE CASCADE,
    CONSTRAINT route_weekdays_day_chk CHECK (day_of_week BETWEEN 1 AND 7)
);

CREATE TABLE railway_hw1.ticket_prices (
    zones_crossed SMALLINT PRIMARY KEY,
    price_amount NUMERIC(10, 2) NOT NULL,
    currency_code CHAR(3) NOT NULL DEFAULT 'RUB',
    CONSTRAINT ticket_prices_zones_chk CHECK (zones_crossed >= 0),
    CONSTRAINT ticket_prices_amount_chk CHECK (price_amount >= 0),
    CONSTRAINT ticket_prices_currency_chk CHECK (currency_code ~ '^[A-Z]{3}$')
);

CREATE TABLE railway_hw1.route_exceptions (
    route_id BIGINT NOT NULL,
    service_date DATE NOT NULL,
    is_running BOOLEAN NOT NULL,
    reason TEXT,
    CONSTRAINT route_exceptions_pk PRIMARY KEY (route_id, service_date),
    CONSTRAINT route_exceptions_route_fk FOREIGN KEY (route_id)
        REFERENCES railway_hw1.train_routes (route_id) ON DELETE CASCADE
);

INSERT INTO railway_hw1.stations (station_name, tariff_zone, direction_order)
VALUES
    ('Люблино', 0, 1),
    ('Депо', 0, 2),
    ('Перерва', 0, 3),
    ('Курьяново', 0, 4),
    ('Москворечье', 0, 5),
    ('Царицыно', 0, 6),
    ('Покровское', 0, 7),
    ('Красный Строитель', 0, 8),
    ('Битца', 0, 9),
    ('Бутово', 0, 10),
    ('Щербинка', 0, 11),
    ('Остафьево', 0, 12),
    ('Силикатная', 1, 13),
    ('Подольск', 1, 14);

INSERT INTO railway_hw1.station_connections (from_station_id, to_station_id)
SELECT s1.station_id, s2.station_id
FROM railway_hw1.stations AS s1
JOIN railway_hw1.stations AS s2
    ON s2.direction_order = s1.direction_order + 1;

INSERT INTO railway_hw1.train_routes (route_number, start_station_id, end_station_id, route_name)
SELECT
    v.route_number,
    s_start.station_id,
    s_end.station_id,
    'Люблино — Подольск (участок маршрута)'
FROM (
    VALUES
        ('7286/7285'),
        ('7288/7287'),
        ('7290/7289'),
        ('7292/7291'),
        ('7294/7293')
) AS v(route_number)
JOIN railway_hw1.stations AS s_start
    ON s_start.station_name = 'Люблино'
JOIN railway_hw1.stations AS s_end
    ON s_end.station_name = 'Подольск';

INSERT INTO railway_hw1.route_stations (
    route_id, sequence_number, station_id, is_stop, arrival_time, departure_time
)
SELECT
    r.route_id,
    t.sequence_number,
    s.station_id,
    TRUE,
    (t.arrival_time + v.shift_minutes * INTERVAL '1 minute')::time,
    (t.departure_time + v.shift_minutes * INTERVAL '1 minute')::time
FROM (
    VALUES
        ('7286/7285', 0),
        ('7288/7287', 12),
        ('7290/7289', 24),
        ('7292/7291', 36),
        ('7294/7293', 48)
) AS v(route_number, shift_minutes)
CROSS JOIN (
    VALUES
        (1, TIME '13:56', TIME '13:57'),
        (2, TIME '13:58', TIME '13:59'),
        (3, TIME '14:01', TIME '14:02'),
        (4, TIME '14:04', TIME '14:05'),
        (5, TIME '14:06', TIME '14:07'),
        (6, TIME '14:10', TIME '14:11'),
        (7, TIME '14:14', TIME '14:15'),
        (8, TIME '14:17', TIME '14:18'),
        (9, TIME '14:20', TIME '14:21'),
        (10, TIME '14:24', TIME '14:25'),
        (11, TIME '14:28', TIME '14:29'),
        (12, TIME '14:31', TIME '14:32'),
        (13, TIME '14:34', TIME '14:35'),
        (14, TIME '14:40', NULL::time)
) AS t(sequence_number, arrival_time, departure_time)
JOIN railway_hw1.train_routes AS r
    ON r.route_number = v.route_number
JOIN railway_hw1.stations AS s
    ON s.direction_order = t.sequence_number;

INSERT INTO railway_hw1.route_weekdays (route_id, day_of_week)
SELECT r.route_id, d.day_of_week
FROM railway_hw1.train_routes AS r
CROSS JOIN generate_series(1, 7) AS d(day_of_week)
WHERE r.route_number <> '7290/7289'
   OR d.day_of_week BETWEEN 1 AND 5;

INSERT INTO railway_hw1.ticket_prices (zones_crossed, price_amount, currency_code)
VALUES
    (0, 75.00, 'RUB'),
    (1, 102.00, 'RUB'),
    (2, 141.00, 'RUB'),
    (3, 180.00, 'RUB'),
    (4, 219.00, 'RUB');

INSERT INTO railway_hw1.route_exceptions (route_id, service_date, is_running, reason)
SELECT r.route_id, e.service_date, e.is_running, e.reason
FROM (
    VALUES
        ('7290/7289', DATE '2026-11-07', TRUE, 'Учебный пример: дополнительный субботний рейс'),
        ('7290/7289', DATE '2026-11-08', TRUE, 'Учебный пример: дополнительный воскресный рейс'),
        ('7286/7285', DATE '2026-11-09', FALSE, 'Учебный пример: отмена рейса'),
        ('7294/7293', DATE '2026-11-14', FALSE, 'Учебный пример: отмена рейса'),
        ('7288/7287', DATE '2026-11-15', FALSE, 'Учебный пример: отмена рейса')
) AS e(route_number, service_date, is_running, reason)
JOIN railway_hw1.train_routes AS r
    ON r.route_number = e.route_number;

COMMIT;

SELECT
    s.station_id,
    s.station_name,
    rs.arrival_time
FROM railway_hw1.route_stations AS rs
JOIN railway_hw1.stations AS s
    ON s.station_id = rs.station_id
WHERE rs.is_stop = TRUE
  AND rs.arrival_time BETWEEN TIME '14:00' AND TIME '15:00'
ORDER BY s.station_id ASC, rs.arrival_time DESC;

SELECT
    d.day_of_week,
    CASE d.day_of_week
        WHEN 1 THEN 'Понедельник'
        WHEN 2 THEN 'Вторник'
        WHEN 3 THEN 'Среда'
        WHEN 4 THEN 'Четверг'
        WHEN 5 THEN 'Пятница'
        WHEN 6 THEN 'Суббота'
        WHEN 7 THEN 'Воскресенье'
    END AS weekday_name,
    COUNT(DISTINCT rs.route_id) AS trains_count
FROM generate_series(1, 7) AS d(day_of_week)
LEFT JOIN railway_hw1.route_weekdays AS rw
    ON rw.day_of_week = d.day_of_week
LEFT JOIN railway_hw1.route_stations AS rs
    ON rs.route_id = rw.route_id
   AND rs.is_stop = TRUE
   AND rs.station_id IN (
       SELECT station_id
       FROM railway_hw1.stations
       WHERE station_name = 'Москворечье'
   )
GROUP BY d.day_of_week
ORDER BY d.day_of_week;
