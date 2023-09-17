--=============== МОДУЛЬ 5. РАБОТА С POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========

SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============
 

--ЗАДАНИЕ №1
--Сделайте запрос к таблице payment и с помощью оконных функций добавьте вычисляемые колонки согласно условиям:
--Пронумеруйте все платежи от 1 до N по дате платежа

--Пронумеруйте платежи для каждого покупателя, сортировка платежей должна быть по дате платежа

--Посчитайте нарастающим итогом сумму всех платежей для каждого покупателя, сортировка должна 
--быть сперва по дате платежа, а затем по размеру платежа от наименьшей к большей

--Пронумеруйте платежи для каждого покупателя по размеру платежа от наибольшего к
--меньшему так, чтобы платежи с одинаковым значением имели одинаковое значение номера.

--Можно составить на каждый пункт отдельный SQL-запрос, а можно объединить все колонки в одном запросе.

select p.customer_id, p.payment_id, p.payment_date,  row_number() over (order by p.payment_date) "Cортировка платежей по дате" ,
row_number () over (partition by p.customer_id order by p.payment_date) "Cорт. покуп./платежей по дате",
sum(p.amount) over (partition by p.customer_id order by p.payment_date, p.amount ) "Нарастающая сумма платежей",
rank () over (partition by p.customer_id order by p.amount desc) "Ранжирование платежей по дате"
from payment p
 

--ЗАДАНИЕ №2
--С помощью оконной функции выведите для каждого покупателя стоимость платежа и стоимость 
--платежа из предыдущей строки со значением по умолчанию 0.0 с сортировкой по дате платежа.

select p.customer_id, p.payment_id, p.payment_id,  p.amount,  lag(amount,1, 0.0) over(partition by p.customer_id order by p.payment_date) "Предыдущий платеж"
from payment p 


--ЗАДАНИЕ №3
--С помощью оконной функции определите, на сколько каждый следующий платеж покупателя больше или меньше текущего.

select p.customer_id, p.payment_id, p.payment_id,  p.amount, p.amount - lead(amount,1, 0.0) over(partition by p.customer_id order by p.payment_date) "Разница платежей" 
from payment p 

--ЗАДАНИЕ №4
--С помощью оконной функции для каждого покупателя выведите данные о его последней оплате аренды.

select p2.customer_id, p2.payment_id, p2.payment_date, p2.amount 
from
(
select *, row_number() over(partition by p.customer_id, order by p.payment_date desc) as last_payment_date
from payment p 
) p2
where p2.last_payment_date = 1


 --======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--С помощью оконной функции выведите для каждого сотрудника сумму продаж за август 2005 года 
--с нарастающим итогом по каждому сотруднику и по каждой дате продажи (без учёта времени) 
--с сортировкой по дате.

select staff_id, date_of_payment, day_amount,  sum(day_amount) over (partition by staff_id order by date_of_payment)  sum_amount
from 
(
select p.staff_id, sum(p.amount) day_amount, p.payment_date::date date_of_payment
from payment p 
where   extract(year from p.payment_date) = 2005
		and
	 	extract(month  from p.payment_date) = 8
group by p.staff_id, date_of_payment
) p2


--ЗАДАНИЕ №2
--20 августа 2005 года в магазинах проходила акция: покупатель каждого сотого платежа получал
--дополнительную скидку на следующую аренду. С помощью оконной функции выведите всех покупателей,
--которые в день проведения акции получили скидку

select *
from
(
select p.customer_id , p.payment_date date_of_payment, 
 row_number() over (order by p.payment_date) as payment_number
from payment p 
where   extract(year from p.payment_date) = 2005
		and
	 	extract(month  from p.payment_date) = 8
	 	and
	 	extract(day  from p.payment_date) = 20
) p2
where mod(p2.payment_number, 100) = 0


--ЗАДАНИЕ №3
--Для каждой страны определите и выведите одним SQL-запросом покупателей, которые попадают под условия:
-- 1. покупатель, арендовавший наибольшее количество фильмов
-- 2. покупатель, арендовавший фильмов на самую большую сумму
-- 3. покупатель, который последним арендовал фильм


with cte_customer_country as( --- связка покупатель - страна
select 
	c.customer_id, 
	c3.country, 
	concat(c.first_name,' ', c.last_name) customer_name
from customer c
	join address a on a.address_id = c.address_id
	join city c2 on c2.city_id = a.city_id
	join country c3 on c3.country_id = c2.country_id
group by c.customer_id , c3.country, customer_name
), 
cte_rental_count as
( --- покупатель, арендовавший наибольшее количество фильмов
select *
from(
	select rc.customer_id, ccc.country, customer_name, rental_count, row_number() over (partition by ccc.country order by rental_count desc) max_rental
	from
	(
		select r.customer_id, count(r.rental_id) rental_count
		from rental r 
		group by r.customer_id
	) rc
	join cte_customer_country ccc on ccc.customer_id = rc.customer_id
) rc_max
where max_rental = 1
),
cte_payment_sum as( --- покупатель, арендовавший фильмов на самую большую сумму
select *
from(
	select ps.customer_id, ccc.country, customer_name, payment_sum, row_number() over (partition by ccc.country order by ps.payment_sum  desc) max_amount
	from
	(
		select p.customer_id, sum(p.amount) payment_sum 
		from payment p 
		group by p.customer_id
	) ps
	join cte_customer_country ccc on ccc.customer_id = ps.customer_id
) ps_sum
where max_amount = 1
),
cte_payment_last as( --- покупатель, который последним арендовал фильм
select *
from
(
	select rl.customer_id, ccc.country, customer_name, rl.rental_last , row_number() over (partition by ccc.country order by rl.rental_last  desc) rental_last_day
	from
	(
		select r.customer_id, max(r.rental_date) rental_last 
		from rental r 
		group by r.customer_id
	) rl
	join cte_customer_country ccc on ccc.customer_id = rl.customer_id
) rl_last
where rental_last_day = 1
)--- финальный запрос
select  crc.country, crc.customer_name, cps.customer_name, cpl.customer_name
from cte_rental_count crc
	join  cte_payment_sum cps on crc.country = cps.country
	join cte_payment_last cpl on cpl.country = crc.country





