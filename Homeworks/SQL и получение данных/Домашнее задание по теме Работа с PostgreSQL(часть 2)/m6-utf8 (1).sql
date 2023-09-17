--=============== МОДУЛЬ 6. POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Напишите SQL-запрос, который выводит всю информацию о фильмах 
--со специальным атрибутом "Behind the Scenes".


select * 
	from film f 
	where f.special_features &&  array['Behind the Scenes']


--ЗАДАНИЕ №2
--Напишите еще 2 варианта поиска фильмов с атрибутом "Behind the Scenes",
--используя другие функции или операторы языка SQL для поиска значения в массиве.

select * 
	from film f 
	where f.special_features @>  array['Behind the Scenes']

select * 
	from film f 
	where array_position( f.special_features, 'Behind the Scenes') > 0


--ЗАДАНИЕ №3
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов 
--со специальным атрибутом "Behind the Scenes.

--Обязательное условие для выполнения задания: используйте запрос из задания 1, 
--помещенный в CTE. CTE необходимо использовать для решения задания.

with cte_film_special as( --- список фильмов с атрибутом 'Behind the Scenes'
select * 
	from film f 
	where array_position( f.special_features, 'Behind the Scenes') is not null
),
cte_film_customer as( --- связь покупатель - фильм с атрибутом
select c.customer_id, cfs.film_id
	from customer c 
		join rental r on r.customer_id = c.customer_id
		join inventory i on r.inventory_id = i.inventory_id
		join cte_film_special cfs on cfs.film_id =  i.film_id
)
select cfc.customer_id, count(cfc.film_id) 
	from cte_film_customer cfc
	group by cfc.customer_id



--ЗАДАНИЕ №4
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов
-- со специальным атрибутом "Behind the Scenes".

--Обязательное условие для выполнения задания: используйте запрос из задания 1,
--помещенный в подзапрос, который необходимо использовать для решения задания.

with cte_film_customer as( --- связь покупатель - диск
select c.customer_id, i.film_id
	from customer c 
		join rental r on r.customer_id = c.customer_id
		join inventory i on r.inventory_id = i.inventory_id
)
select cfc.customer_id, count(fid.film_id)
	from 
	(
	select * 
		from film f 
		where array_position( f.special_features, 'Behind the Scenes') is not null
	) fid
	join cte_film_customer cfc on cfc.film_id = fid.film_id
group by cfc.customer_id



--ЗАДАНИЕ №5
--Создайте материализованное представление с запросом из предыдущего задания
--и напишите запрос для обновления материализованного представления

create materialized view 
customer_film
as
(
with cte_film_customer as( --- связь покупатель - диск
select c.customer_id, i.film_id
	from customer c 
		join rental r on r.customer_id = c.customer_id
		join inventory i on r.inventory_id = i.inventory_id
)
select cfc.customer_id, count(fid.film_id)
	from 
	(
	select * 
		from film f 
w		here array_position( f.special_features, 'Behind the Scenes') is not null
	) fid
		join cte_film_customer cfc on cfc.film_id = fid.film_id
	group by cfc.customer_id
)
with no data

refresh materialized view 
customer_film



--ЗАДАНИЕ №6
--С помощью explain analyze проведите анализ стоимости выполнения запросов из предыдущих заданий и ответьте на вопросы:
--1. с каким оператором или функцией языка SQL, используемыми при выполнении домашнего задания: 
--поиск значения в массиве затрачивает меньше ресурсов системы;

меньше затрат ресурсов при запросах с операторами 

--2. какой вариант вычислений затрачивает меньше ресурсов системы: 
--с использованием CTE или с использованием подзапроса.


одинаково затрачивают ресурсы


--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выполняйте это задание в форме ответа на сайте Нетологии

--ЗАДАНИЕ №2
--Используя оконную функцию выведите для каждого сотрудника
--сведения о самой первой продаже этого сотрудника.

with cte_payment_date_rank as
(
select *, row_number() over (partition by p.staff_id  order by p.payment_date) p_date
from payment p
),
cte_payment_film as
(
select p.payment_id,f.film_id, f.title
from payment p 
join rental r on r.rental_id = p.rental_id
join inventory i on i.inventory_id = r.inventory_id
join film f on  i.film_id = f.film_id
)
select p.staff_id , f.film_id, f.title, p.amount, p.payment_date, c.last_name customer_last_name, c.first_name customer_first_name
from payment p 
	join cte_payment_film f on  p.payment_id = f.payment_id
	join customer c on c.customer_id = p.customer_id
	join cte_payment_date_rank r on r.payment_id = p.payment_id
where r.p_date = 1



--ЗАДАНИЕ №3
--Для каждого магазина определите и выведите одним SQL-запросом следующие аналитические показатели:
-- 1. день, в который арендовали больше всего фильмов (день в формате год-месяц-день)
-- 2. количество фильмов взятых в аренду в этот день
-- 3. день, в который продали фильмов на наименьшую сумму (день в формате год-месяц-день)
-- 4. сумму продажи в этот день


with cte_store_film as
(
select *
	from
	(
	select *, row_number() over (partition by store_id order by rental_count desc) rental_count_rank
		from
	(
	select s.store_id,  r.rental_date::date r_day,  count(r.rental_id) rental_count  
		from rental r 
			join store s on s.manager_staff_id = r.staff_id 
		group by r_day,  s.store_id
	) store_rental_day_count
	) store_max_rental_day_info
where  rental_count_rank = 1
),
cte_store_payment as
(
select *
	from
	(
	select *, row_number() over (partition by store_id order by payment_sum ) payment_sum_rank
		from 
	(
	select s.store_id, p.payment_date::date p_day, sum(p.amount) payment_sum
		from payment p 
			join store s on s.manager_staff_id = p.staff_id 
		group by s.store_id, p_day
	) store_payment_day_sum
	) store_payment_day_sum_rank
where payment_sum_rank = 1
)
select c.store_id, c.r_day, c.rental_count, c2.p_day, c2.payment_sum
	from cte_store_film c
		join cte_store_payment c2 on c.store_id = c2.store_id






