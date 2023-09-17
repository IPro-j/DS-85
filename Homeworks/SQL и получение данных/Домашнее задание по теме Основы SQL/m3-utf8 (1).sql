--=============== МОДУЛЬ 3. ОСНОВЫ SQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выведите для каждого покупателя его адрес проживания, 
--город и страну проживания.

select c.customer_id, a.address, c2.city, c3.country 
from customer c
join address a on  c.address_id = a.address_id 
join city c2 on a.city_id = c2.city_id 
join country c3 on c2.country_id = c3.country_id 



--ЗАДАНИЕ №2
--С помощью SQL-запроса посчитайте для каждого магазина количество его покупателей.

select s.store_id, count(c.customer_id)
from store s 
join customer c on s.store_id = c.store_id 
group by s.store_id 


--Доработайте запрос и выведите только те магазины, 
--у которых количество покупателей больше 300-от.
--Для решения используйте фильтрацию по сгруппированным строкам 
--с использованием функции агрегации.

select s.store_id, count(c.customer_id)
from store s 
join customer c on s.store_id = c.store_id 
group by s.store_id 
having count(c.customer_id) > 300


-- Доработайте запрос, добавив в него информацию о городе магазина, 
--а также фамилию и имя продавца, который работает в этом магазине.

select s.store_id, count(c.customer_id), c2.city,  s2.last_name, s2.first_name 
from store s 
join customer c on s.store_id = c.store_id 
join staff s2 on s.manager_staff_id = s2.staff_id 
join address a on  s.address_id = a.address_id 
join city c2 on a.city_id = c2.city_id 
group by s.store_id,  c2.city,  s2.last_name, s2.first_name 
having count(c.customer_id) > 300



--ЗАДАНИЕ №3
--Выведите ТОП-5 покупателей, 
--которые взяли в аренду за всё время наибольшее количество фильмов

select c.customer_id, count(r.rental_id)
from customer c 
join rental r on c.customer_id = r.customer_id 
group by c.customer_id
order by count(r.rental_id) desc
limit 5



--ЗАДАНИЕ №4
--Посчитайте для каждого покупателя 4 аналитических показателя:
--  1. количество фильмов, которые он взял в аренду
--  2. общую стоимость платежей за аренду всех фильмов (значение округлите до целого числа)
--  3. минимальное значение платежа за аренду фильма
--  4. максимальное значение платежа за аренду фильма


select c.customer_id, count(r.rental_id), round(sum(p.amount)) summa, min(p.amount) minimum, max(p.amount)  maximum
from customer c 
join rental r on c.customer_id = r.customer_id 
join payment p on p.rental_id  = r.rental_id 
group by c.customer_id


--ЗАДАНИЕ №5
--Используя данные из таблицы городов, составьте все возможные пары городов так, чтобы 
--в результате не было пар с одинаковыми названиями городов. Решение должно быть через Декартово произведение.


SELECT c.city, c2.city 
from city c
cross join city c2
where c.city != c2.city

--ЗАДАНИЕ №6
--Используя данные из таблицы rental о дате выдачи фильма в аренду (поле rental_date) и 
--дате возврата (поле return_date), вычислите для каждого покупателя среднее количество 
--дней, за которые он возвращает фильмы. В результате должны быть дробные значения, а не интервал.


select r.customer_id, round(EXTRACT(epoch FROM avg((r.return_date - r.rental_date)))/86400, 2)
from rental r
group by r.customer_id

--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Посчитайте для каждого фильма сколько раз его брали в аренду и значение общей стоимости аренды фильма за всё время.


select f.film_id "Фильм", count(i.inventory_id) "Кол-во аренды", sum(p.amount) "Общая стоимость"  
from film f 
join inventory i on f.film_id = i.film_id 
join rental r on i.inventory_id  = r.inventory_id 
join payment p on r.rental_id = p.payment_id 
group by f.film_id


--ЗАДАНИЕ №2
--Доработайте запрос из предыдущего задания и выведите с помощью него фильмы, которые отсутствуют на dvd дисках.


select distinct  f.film_id, f.title,  i.film_id 
from film f  
left outer join inventory i  on f.film_id = i.film_id 
where i.film_id is null


--ЗАДАНИЕ №3
--Посчитайте количество продаж, выполненных каждым продавцом. Добавьте вычисляемую колонку "Премия".
--Если количество продаж превышает 7300, то значение в колонке будет "Да", иначе должно быть значение "Нет".


select p.staff_id, count(payment_id) "количество продаж", 
case
	when count(payment_id) > 7300 then 'Да'
	else 'Нет'
end "Премия"
from payment p 
group by p.staff_id







