SET search_path TO bookings;


--1
--Выведите названия самолётов, которые имеют менее 50 посадочных мест.

select a.aircraft_code, count(s.seat_no) seat_count
 from aircrafts a 
 join seats s on a.aircraft_code = s.aircraft_code 
 group by a.aircraft_code
 having count(s.seat_no) < 50


--2
--Выведите процентное изменение ежемесячной суммы бронирования билетов, округленной до сотых.

select *, round( 100 * (sum_book_amount - prev_book_amount) / prev_book_amount, 2 ) "процентное изменение "
from
(
	select book_month, sum_book_amount , lag(sum_book_amount, 1) over (order by book_month) prev_book_amount
	from 
	(
		select to_char(b.book_date , 'YYYY-MM')  book_month, sum(b.total_amount) sum_book_amount
		from bookings b 
		group by book_month
	)month_amount 
) book_change
-- проверить вручную, версию с cte, комментарии



--3
--Выведите названия самолётов без бизнес-класса. Используйте в решении функцию array_agg.

--select model 
select a.model
 from(
 select s2.aircraft_code, array_agg(s2.fare_conditions::text) && array['Business'] has_business
  from (
   select distinct s.aircraft_code, s.fare_conditions
    from seats s
   ) s2
 group by s2.aircraft_code
) s3
join aircrafts a on a.aircraft_code = s3.aircraft_code
where s3.has_business = false


--4
--Выведите накопительный итог количества мест в самолётах по каждому аэропорту на каждый день. 
--Учтите только те самолеты, которые летали пустыми и только те дни, когда из одного аэропорта вылетело более одного такого самолёта.
--Выведите в результат код аэропорта, дату вылета, количество пустых мест и накопительный итог.


with seat_count as( -- кол-во мест в самолете
	select a.aircraft_code, count(s.seat_no) seat_count
	from aircrafts a 
	join seats s on s.aircraft_code = a.aircraft_code
	group by a.aircraft_code
)
select airport, flight_day, day_seat_count, sum(day_seat_count) over (partition by airport order by airport, flight_day)
from (
	select f1.airport, f1.flight_day, sum(sc.seat_count) day_seat_count
	from 
	(-- выбираем рейсы, с заполненной датой вылета и не имеющих зарегистрированных пассажиоов
	select f.aircraft_code, f.departure_airport airport, f.actual_departure::date flight_day
		from flights f
		where f.actual_departure notnull
		and 	f.flight_id not in (select distinct bp.flight_id from boarding_passes bp)
		) f1
join seat_count sc on sc.aircraft_code = f1.aircraft_code 
group by f1.airport, f1.flight_day
having count(*) = 14
) f3


	
--5
--Найдите процентное соотношение перелётов по маршрутам от общего количества перелётов. 
--Выведите в результат названия аэропортов и процентное отношение.
--Используйте в решении оконную функцию.

select distinct r.departure_airport_name , r.arrival_airport_name, 
round(100.0*count(*) over (partition by r.departure_airport_name , r.arrival_airport_name) / count(*) over (), 2) "Процентное соотношение перелётов"
from routes r 


--6
--Выведите количество пассажиров по каждому коду сотового оператора. 
--Код оператора – это три символа после +7

select operator_code, count(*) "количество пассажиров"
from (
	select substring(t.contact_data['phone']::text, position( '+7' in t.contact_data['phone']::text)+2 , 3) operator_code
	from tickets t 
) t1
group by operator_code

--7
--Классифицируйте финансовые обороты (сумму стоимости билетов) по маршрутам:
--до 50 млн – low
--от 50 млн включительно до 150 млн – middle
--от 150 млн включительно – high
--Выведите в результат количество маршрутов в каждом полученном классе.

with route_amount as
(
select f.departure_airport , f.arrival_airport , sum(tf.amount) sum_amount,
case 
	when sum(tf.amount) < 50000000 then 'low'
	when sum(tf.amount) >= 50000000 and  sum(tf.amount) < 150000000 then 'middle'
	when sum(tf.amount) >= 150000000 then 'high' 
end  route_amount
from flights f 
join ticket_flights tf on tf.flight_id = f.flight_id 
group by f.departure_airport , f.arrival_airport
)
select  route_amount, count(route_amount)
from route_amount ra
group by route_amount


--8
--Вычислите медиану стоимости билетов, медиану стоимости бронирования 
--и отношение медианы бронирования к медиане стоимости билетов, результат округлите до сотых. 

with 
ticket_median as(
	select  percentile_disc(0.5) within group (order by tf.amount) ticket_median
	from ticket_flights tf
),
booking_median as(
	select percentile_disc(0.5) within group (order by b.total_amount) booking_median
	from bookings b
)
select *, round(booking_median/ticket_median,2) "Отношение медиан"
from ticket_median, booking_median ;



--9
--Найдите значение минимальной стоимости одного километра полёта для пассажира. 
--Для этого определите расстояние между аэропортами и учтите стоимость билетов.
--Для поиска расстояния между двумя точками на поверхности Земли используйте дополнительный модуль earthdistance. 
--Для работы данного модуля нужно установить ещё один модуль – cube.
--Важно: 
--Установка дополнительных модулей происходит через оператор CREATE EXTENSION название_модуля.
--В облачной базе данных модули уже установлены.
--Функция earth_distance возвращает результат в метр


CREATE EXTENSION IF NOT EXISTS earthdistance SCHEMA bookings CASCADE ;

select  
round(min( tf.amount / (earth_distance ( ll_to_earth(a.latitude, a.longitude), ll_to_earth(a2.latitude, a2.longitude))/1000))::numeric, 2) "мин. стоимостm километра"
from flights f 
join airports a on a.airport_code = f.departure_airport 
join airports a2 on a2.airport_code = f.arrival_airport 
join ticket_flights tf on tf.flight_id = f.flight_id 



