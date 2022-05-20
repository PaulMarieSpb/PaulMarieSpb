use classicmodels;
/*   Here I create the catergories for customer by monetary */
WITH Percentiles AS (SELECT sum(orderdetails.priceEach * orderdetails.quantityOrdered) AS spending,c.customerNumber,c.customerName,
                    PERCENT_RANK() OVER(
                    ORDER BY sum(orderdetails.priceEach * orderdetails.quantityOrdered)) AS Percent_
             FROM orderdetails
             INNER JOIN orders o1
  USING (orderNumber)
  INNER JOIN customers c
  USING (customerNumber)
  GROUP BY c.customerNumber)
  SELECT *,
      case when Percent_ >= 0 AND Percent_ <= 0.25 THEN '4'
      when Percent_ > 0.25 AND Percent_ <= 0.5 THEN '3'
      WHEN Percent_ > 0.5 AND Percent_ <= 0.75 THEN '2'
      ELSE '1' END AS monetary_cat


         FROM Percentiles;

/*   Here I create the catergories for customer by date */
WITH category_recency AS(
WITH percentiles_Date AS ( SELECT DATEDIFF(max(orderDate), clt_date) AS recency, last_order.customerNumber, PERCENT_RANK() OVER(ORDER BY max(orderDate), clt_date) AS date_percentile
FROM orders
INNER JOIN (SELECT max(orderDate) AS clt_date, customerNumber
From orders
GROUP BY customerNumber) As last_order
GROUP BY last_order.customerNumber)
SELECT *,
      case when date_percentile >= 0 AND date_percentile <= 0.20 THEN '1'
      when date_percentile > 0.20 AND date_percentile <= 0.4 THEN '2'
      WHEN date_percentile> 0.4 AND date_percentile <= 0.6 THEN '3'
        WHEN date_percentile> 0.6 AND date_percentile <= 0.8 THEN '4'
      ELSE '5' END AS rec_cat
FROM percentiles_Date),

category_frequency AS(
WITH percentile_order AS (
Select count(orderNumber) as frequency, customerNumber, PERCENT_RANK() OVER(ORDER BY count(orderNumber)) AS percent_order
FROM orders
GROUP BY customerNumber)
SELECT *,
      case when percent_order >= 0 AND percent_order <= 0.2 THEN '1'
      when percent_order > 0.2 AND percent_order <= 0.4 THEN '2'
      WHEN percent_order> 0.4 AND percent_order <= 0.6 THEN '3'
          WHEN percent_order> 0.6 AND percent_order <= 0.8 THEN '4'
      ELSE '5' END AS freq_cat
FROM percentile_order),

    category_Monetary AS(
WITH Percentiles AS (SELECT sum(orderdetails.priceEach * orderdetails.quantityOrdered) AS monetary,c.customerNumber,c.customerName,
                    PERCENT_RANK() OVER(
                    ORDER BY sum(orderdetails.priceEach * orderdetails.quantityOrdered)) AS Percent_
             FROM orderdetails
             INNER JOIN orders o1
  USING (orderNumber)
  INNER JOIN customers c
  USING (customerNumber)
  GROUP BY c.customerNumber)
  SELECT *,
      case when Percent_ >= 0 AND Percent_ <= 0.2 THEN '1'
      when Percent_ > 0.2 AND Percent_ <= 0.4 THEN '2'
      WHEN Percent_ > 0.4 AND Percent_ <= 0.6 THEN '3'
        WHEN Percent_ > 0.6 AND Percent_ <= 0.8 THEN '4'
      ELSE '5' END AS mon_cat


         FROM Percentiles
    )
SELECT customerNumber, c.customerName,rec_cat, freq_cat, mon_cat,country,recency,frequency,monetary, concat(rec_cat,freq_cat,mon_cat) AS rfm_score,
       case when concat(rec_cat,freq_cat,mon_cat) IN ('555', '554', '544', '545', '454', '455', '445') Then 'Champion'
           when concat(rec_cat,freq_cat,mon_cat) IN ('543', '444', '435', '355', '354', '345', '344', '335') THEN 'Loyal'
           when concat(rec_cat,freq_cat,mon_cat) IN ('553', '551', '552', '541', '542', '533', '532', '531', '452',
                                                     '451', '442', '441', '431', '453', '433', '432', '423',
                                                     '353', '352', '351', '342', '341', '333', '323') THEN 'Potentiel loyalist'
           when concat(rec_cat,freq_cat,mon_cat) IN ('512', '511', '422', '421', '412', '411', '311') THEN 'New customers'
           when concat(rec_cat,freq_cat,mon_cat) IN ('525', '524', '523', '522', '521', '515', '514', '513', '425','424',
                                                     '413','414','415', '315', '314', '313') THEN 'Promising'
           when concat(rec_cat,freq_cat,mon_cat) IN ('535', '534', '443', '434', '343', '334', '325', '324') THEN 'Need Attention'
           when concat(rec_cat,freq_cat,mon_cat) IN ('331', '321', '312', '221', '213', '231', '241', '251') THEN 'About To sleep'
           when concat(rec_cat,freq_cat,mon_cat) IN ('255', '254', '245', '244', '253', '252', '243', '242', '235', '234', '225', '224',
                                                     '153', '152', '145', '143', '142', '135', '134', '133', '125', '124') THEN 'At risk'
           when concat(rec_cat,freq_cat,mon_cat) IN ('155', '154', '144', '214','215','115', '114', '113') THEN 'Cannot Lose Them'
        when concat(rec_cat,freq_cat,mon_cat) IN ('332', '322', '233', '232', '223', '222', '132', '123', '122',
                                                      '212', '211') THEN 'Hibernating customers'
           when concat(rec_cat,freq_cat,mon_cat) IN ('111', '112', '121', '131','141','151') THEN 'Lost customers'
    Else 'Unknown' END as category
FROM category_recency
INNER JOIN category_frequency
USING (customerNumber)
INNER JOIN category_Monetary
USING (customerNumber)
INNER JOIN customers c
USING (customerNumber);