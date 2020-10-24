/* VYPIŠ KATEGORIE S ALESPOŇ JEDNÍM PRODUKTEM V PODKATEGORIÍCH SEKCE */

/* 1.a hierarchy query */
select TC.* from T_CATEGORY TC
     left join T_PRODUCT_CATEGORY TPC on TC.CATEGORY_ID = TPC.CATEGORY_ID
     left join T_PRODUCT TP on TP.PRODUCT_ID = TPC.PRODUCT_ID
where TP.PRODUCT_ID is not null
start with TC.CATEGORY_ID = 2
connect by prior TC.CATEGORY_ID = TC.PARENT;

/* 1.b join query */
SELECT t3.*
FROM T_CATEGORY t1
         LEFT JOIN T_CATEGORY t2 ON t2.parent = t1.category_id
         LEFT JOIN T_CATEGORY t3 ON t3.parent = t2.category_id
         LEFT JOIN T_PRODUCT_CATEGORY TPC on t1.CATEGORY_ID = TPC.CATEGORY_ID OR t2.CATEGORY_ID = TPC.CATEGORY_ID OR t3.CATEGORY_ID = TPC.CATEGORY_ID
         LEFT JOIN T_PRODUCT TP on TP.PRODUCT_ID = TPC.PRODUCT_ID
where TP.PRODUCT_ID is not null
        and t1.CATEGORY_ID = 2;

/* 2. like query */
select TC.* from T_CATEGORY TC
         left join T_PRODUCT_CATEGORY TPC on TC.CATEGORY_ID = TPC.CATEGORY_ID
         left join T_PRODUCT TP on TP.PRODUCT_ID = TPC.PRODUCT_ID
where TP.PRODUCT_ID is not null
        and TC.PATH like '/0/1/2/%';

/* 3.a MPTT query */
select TC.* from T_CATEGORY TC
     left join T_PRODUCT_CATEGORY TPC on TC.CATEGORY_ID = TPC.CATEGORY_ID
     left join T_PRODUCT TP on TP.PRODUCT_ID = TPC.PRODUCT_ID
where TC.LEFT >= 3
        and TC.RIGHT <= 21052
        and TP.PRODUCT_ID is not null;

/* 3.b MPTT de-normalized query */
select TC.* from T_CATEGORY TC
     inner join T_PRODUCT TP on TC.LEFT = TP.LEFT and TC.RIGHT = TP.RIGHT
where TP.LEFT > 3 and TP.RIGHT < 21052;

/* VYPIŠ KATEGORIE S POČTEM PRODUKTŮ V NICH */

/* 1. hierarchy query */
select TC.*, A.PRODUCT_COUNT from T_CATEGORY TC
                                      inner join (
    select t1.CATEGORY_ID, count(0) as PRODUCT_COUNT
    from T_CATEGORY t1
             left join T_PRODUCT_CATEGORY TPC on t1.CATEGORY_ID = TPC.CATEGORY_ID
             left join T_PRODUCT TP on TP.PRODUCT_ID = TPC.PRODUCT_ID
    where TP.PRODUCT_ID is not null
    start with t1.CATEGORY_ID = 2
    connect by prior t1.CATEGORY_ID = t1.PARENT
    group by t1.CATEGORY_ID
    having count(0) > 0
) a on a.CATEGORY_ID = TC.CATEGORY_ID;

/* 2. like query */
select TC.*, A.PRODUCT_COUNT from T_CATEGORY TC
                                      inner join (
    select T_CATEGORY.CATEGORY_ID, count(0) as PRODUCT_COUNT
    from T_CATEGORY
             left join T_PRODUCT_CATEGORY TPC on T_CATEGORY.CATEGORY_ID = TPC.CATEGORY_ID
             left join T_PRODUCT TP on TP.PRODUCT_ID = TPC.PRODUCT_ID
    where TP.PRODUCT_ID is not null and T_CATEGORY.PATH like '/0/1/2/%'
    group by T_CATEGORY.CATEGORY_ID
    having count(0) > 0
) a on a.CATEGORY_ID = TC.CATEGORY_ID;

/* 3. MPTT query */
select TC.*, A.PRODUCT_COUNT from T_CATEGORY TC
                                      inner join (
    select T_CATEGORY.CATEGORY_ID, count(0) as PRODUCT_COUNT
    from T_CATEGORY
             left join T_PRODUCT_CATEGORY TPC on T_CATEGORY.CATEGORY_ID = TPC.CATEGORY_ID
             left join T_PRODUCT TP on TP.PRODUCT_ID = TPC.PRODUCT_ID
    where T_CATEGORY.LEFT >= 3 and T_CATEGORY.RIGHT <= 21052
            and TP.PRODUCT_ID is not null
    group by T_CATEGORY.CATEGORY_ID
    having count(0) > 0
) a on a.CATEGORY_ID = TC.CATEGORY_ID;

/* 4. MPTT de-normalized query */
select TC.*, A.PRODUCT_COUNT from T_CATEGORY TC
  inner join (
    select left, right, count(0) as PRODUCT_COUNT from T_PRODUCT TP
    where TP.LEFT >= 3 and TP.RIGHT <= 21052
    group by left, RIGHT
) a on TC.LEFT = a.LEFT and TC.RIGHT = a.RIGHT;

/* VYPIŠ NADŘÍZENÉ KATEGORIE */

/* 1. hierarchy query */
select * from T_CATEGORY
start with T_CATEGORY.CATEGORY_ID = 4
connect by prior T_CATEGORY.PARENT = T_CATEGORY.CATEGORY_ID;

/* 2. like query */
select * from T_CATEGORY
where CATEGORY_ID in (
    select regexp_substr(a.PATH, '[^/]+', 1, level)
    from (select concat(PATH, concat('/', concat(CATEGORY_ID, '/'))) as PATH from T_CATEGORY where CATEGORY_ID = 4) a
    connect BY regexp_substr(a.PATH, '[^/]+', 1, level) is not null)
order by LVL desc;

/* 3. MPTT query */
select TC.* from T_CATEGORY TC
where TC.LEFT <= 5 and TC.RIGHT >= 15
order by LVL desc;

/* VYPIŠ PRODUKTY V SEKCI */

/* 1. hierarchy query */
select TP.*
from T_CATEGORY TC
         left join T_PRODUCT_CATEGORY TPC on TC.CATEGORY_ID = TPC.CATEGORY_ID
         left join T_PRODUCT TP on TP.PRODUCT_ID = TPC.PRODUCT_ID
where TP.PRODUCT_ID is not null
start with TC.CATEGORY_ID = 2
connect by prior TC.CATEGORY_ID = TC.PARENT;

/* 2. like query */
select TP.* from T_CATEGORY
                     left join T_PRODUCT_CATEGORY TPC on T_CATEGORY.CATEGORY_ID = TPC.CATEGORY_ID
                     left join T_PRODUCT TP on TP.PRODUCT_ID = TPC.PRODUCT_ID
where TP.PRODUCT_ID is not null and T_CATEGORY.PATH like '/0/1/2/%';

/* 3. MPTT query */
select TP.* from T_CATEGORY
                     left join T_PRODUCT_CATEGORY TPC on T_CATEGORY.CATEGORY_ID = TPC.CATEGORY_ID
                     left join T_PRODUCT TP on TP.PRODUCT_ID = TPC.PRODUCT_ID
where T_CATEGORY.LEFT >= 3 and T_CATEGORY.RIGHT <= 21052
        and TP.PRODUCT_ID is not null;

/* 4. MPTT de-normalized query */
select TP.* from T_PRODUCT TP
where TP.LEFT >= 3 and TP.RIGHT <= 21052;