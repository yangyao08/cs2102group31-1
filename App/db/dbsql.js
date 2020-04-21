/*------ List of SQL Statements ---*/
const sql = {}


sql.query = {

    /*--------Login-----------*/
    login:  'SELECT DISTINCT U.username, U.password, U.name, U.uid, U.type As type , DR.type As ridertype ' +
            'FROM Users U Left Join DeliveryRiders DR on U.uid = DR.uid WHERE U.username = $1',

    /*------Restaurant Staff--------*/
    restInfo:   'SELECT DISTINCT * FROM Restaurants R ' +
                'INNER JOIN RestaurantStaff RS on R.restaurantID =  RS.restaurantID ' +
                'WHERE RS.uid = $1 LIMIT 1',
    restMenuInfo:   'SELECT DISTINCT * FROM Food F ' +
                    'INNER JOIN Restaurants R on F.restaurantID = R.restaurantID ' +
                    'WHERE R.restaurantID = $1',
    restInsertFood: 'INSERT INTO Food(foodName, price, category, restaurantID) ' +
                    'Values($1, $2, \'Western\', $3)',
    restOrders:     'SELECT DISTINCT FM.orderID, to_char(O.date, \'DD/MM/YYYY\') as date, O.timeOrderPlace, FM.FoodName, FM.quantity ' +
                    'FROM Orders O INNER JOIN FromMenu FM on O.orderID = FM.orderID ' +
                    'WHERE O.orderStatus = \'Confirmed\'  AND O.timeDepartFromRest IS NULL AND FM.restaurantID = $1 ' + 
                    'AND FM.hide = \'false\' ORDER BY date, O.timeOrderPlace, FM.orderID',
    restCooked:     'UPDATE FromMenu SET hide = \'true\' WHERE orderID = $1 and foodName = $2',
    restSummary:    'SELECT year, month, COUNT(orderID) AS totalorders, SUM(cost) As totalCost ' +
                    'FROM (SELECT DISTINCT EXTRACT(Year FROM (O.date)) AS year, to_char(O.date, \'Month\') as month, '+
                    'O.orderid, O.cost FROM Orders O INNER JOIN FromMenu FM on O.orderID = FM.orderID ' +
                    'WHERE O.orderStatus = \'Completed\' AND FM.restaurantID = $1) TMP ' +
                    'GROUP BY year, month ORDER BY year DESC, to_date(month, \'Month \') DESC',
    restFavFood:    'With FoodOrders as ( SELECT EXTRACT(Year FROM (O.date)) AS year,  to_char(O.date, \'Month\') as month, ' +
                    'FM.foodName as food, SUM(FM.quantity) as totalOrders FROM FromMenu FM INNER JOIN Orders O on FM.orderID = O.orderID ' +
                    'WHERE O.orderStatus = \'Completed\' AND FM.restaurantID = $1 ' +
                    'GROUP BY EXTRACT(Year FROM (O.date)),  to_char(O.date, \'Month\'), FM.foodName) ' +
                    'SELECT DISTINCT * FROM ( SELECT year, month, to_date(month, \'Month \') as month2, food, totalOrders, '+
                    'row_number() OVER (PARTITION BY year, month) as rownum FROM FoodOrders ' +
                    ')Tmp WHERE rownum < 6 ORDER BY year DESC, month2 DESC, totalOrders DESC',
    restPercPromo:      'INSERT INTO Promotion(startDate, endDate, startTime, endTime, discPerc, type) ' +
                        'Values($1, $2, $3, $4, $5, \'Restpromo\') RETURNING promoID',
    restAmtPromo:       'INSERT INTO Promotion(startDate, endDate, startTime, endTime, discAmt, type) ' +
                        'Values($1, $2, $3, $4, $5, \'Restpromo\') RETURNING promoID',
    restInsertPromo:    'INSERT INTO Restpromo(promoID, restID) VALUES($1, $2)',
    restPercSummary:    'With PromoInfo AS (SELECT DISTINCT P.promoID, startDate,  startTime, endDate, endTime, discPerc, ' +
                        'DATE_PART( \'day\',  (startDate + startTime) -  (endDate + endTime)) as dayDuration, ' +
                        'DATE_PART( \'day\', (startDate + startTime) - ( endDate + endTime)) * 24 + ' +
                        'DATE_PART( \'hour\', (startDate + startTime) - (endDate + endTime)) as hourDuration ' +
                        'FROM Restpromo R INNER JOIN Promotion P on R.promoID = P.promoID ' +
                        'WHERE P.discPerc IS NOT NULL  AND R.restID = $1), ' +
                        'OrderInfo As (SELECT DISTINCT P.promoID, COUNT(DISTINCT orderID) as totalOrders ' +
                        'FROM Promotion P INNER JOIN FromMenu FM on P.promoID = FM.promoID ' +
                        'WHERE P.discPerc IS NOT NULL ' +
                        'GROUP BY P.promoID AND FM.restaurantID = $2) ' +
                        'SELECT DISTINCT PI.promoID, startDate, startTime, endDate, endTime, discPerc, totalOrders, dayDuration, hourDuration, ' +
                        'ROUND(totalOrders::decimal / dayDuration) as dayAvg, ROUND(totalOrders::decimal/ hourDuration) as hourAvg ' +
                        'FROM PromoInfo PI INNER JOIN OrderInfo O on PI.promoID = O.promoID',
     restAmtSummary:    'With PromoInfo AS (SELECT DISTINCT P.promoID, startDate,  startTime, endDate, endTime, discAmt, ' +
                        'DATE_PART( \'day\',  (startDate + startTime) -  (endDate + endTime)) as dayDuration, ' +
                        'DATE_PART( \'day\', (startDate + startTime) - ( endDate + endTime)) * 24 + ' +
                        'DATE_PART( \'hour\', (startDate + startTime) - (endDate + endTime)) as hourDuration ' +
                        'FROM Restpromo R INNER JOIN Promotion P on R.promoID = P.promoID ' +
                        'WHERE P.discAmt IS NOT NULL  AND R.restID = $1), ' +
                        'OrderInfo As (SELECT DISTINCT P.promoID, COUNT(DISTINCT orderID) as totalOrders ' +
                        'FROM Promotion P INNER JOIN FromMenu FM on P.promoID = FM.promoID ' +
                        'WHERE P.discAmt IS NOT NULL ' +
                        'GROUP BY P.promoID AND FM.restaurantID = $2) ' +
                        'SELECT DISTINCT PI.promoID, startDate, startTime, endDate, endTime, discAmt, totalOrders, dayDuration, hourDuration, ' +
                        'ROUND(totalOrders::decimal / dayDuration) as dayAvg, ROUND(totalOrders::decimal/ hourDuration) as hourAvg ' +
                        'FROM PromoInfo PI INNER JOIN OrderInfo O on PI.promoID = O.promoID',
  
    totalOrders: 'Select X.num From ( SELECT EXTRACT(MONTH FROM (date)) AS month, COUNT(orderid) AS num FROM Orders GROUP BY EXTRACT(MONTH FROM (date))) as X Where CAST(X.month as INT) = $1',
    totalCost: 'Select X.num From ( SELECT EXTRACT(MONTH FROM (date)) AS month, SUM(cost) AS num FROM Orders GROUP BY EXTRACT(MONTH FROM (date))) as X Where CAST(X.month as INT) = $1',
    totalNewCus: 'Select X.num From ( SELECT EXTRACT(MONTH FROM (signupDate)) AS month, COUNT(distinct uid) AS num FROM Customers GROUP BY EXTRACT(MONTH FROM (signupDate))) as X Where CAST(X.month as INT) = $1',
    totalOrderEachCust: 'Select x.customer, x.totalcost, x.num From ( SELECT EXTRACT(MONTH FROM (date)) AS month, uid as Customer, SUM(cost) AS totalcost, count(cost) as num FROM (Orders natural join (Place natural join Customers)) GROUP BY uid,EXTRACT(MONTH FROM (Date))) as X Where CAST(X.month as INT) = $1',
    //totalSpendingEachCust: 'Select X.customer, x.totalcost From ( SELECT EXTRACT(MONTH FROM (date)) AS month, uid as Customer, SUM(cost) AS totalcost FROM Orders natural join (Place natural join Customers) GROUP BY uid,EXTRACT(MONTH FROM (Date))) as X Where CAST(X.month as INT) = $1',
    activeCus: 'Select X.num From ( SELECT EXTRACT(MONTH FROM (date)) AS month, COUNT(uid) as num FROM Place natural join Orders GROUP BY EXTRACT(MONTH FROM (date))) as X Where CAST(X.month as INT) = $1',

    viewArea: 'Select X.area, X.hour, X.num From(SELECT EXTRACT(HOUR FROM (timeorderplace)) AS hour, area, COUNT(*) AS num FROM Orders GROUP BY EXTRACT(HOUR FROM (timeorderplace)), area) as X WHERE X.area = $1',
    viewCat: 'Select * from categories',

    insertCat: 'INSERT INTO categories(category) Values($1)',

    fdsPercentPromo: 'INSERT INTO Promotion(startDate, endDate, discPerc, type) ' +
        'Values($1, $2, $3, \'FDSpromo\') RETURNING promoID',
    fdsAmtPromo: 'INSERT INTO Promotion(startDate, endDate, discAmt, type) ' +
        'Values($1, $2, $3, \'FDSpromo\') RETURNING promoID',
    fdsInsertPromo: 'INSERT INTO FDSpromo(promoID) VALUES($1)',
    promoInfo: 'Select * from Promotion',

    riderInfo:    'SELECT * FROM DeliveryRiders WHERE uid = $1',
    ratingInfo:   'SELECT CAST(avg(rating) AS DECIMAL(10,2)) AS rating FROM Delivers GROUP BY (uid) HAVING uid = $1',
    workdInfo:    'SELECT year AS year,to_char(to_timestamp (month::text, \'MM\'), \'Month\') AS month, numCompleted AS com, totalHours as hour FROM workDetails WHERE uid = $1 ORDER BY (year,month) DESC LIMIT 10',
    salaryInfo:   'SELECT year AS year,to_char(to_timestamp (month::text, \'MM\'), \'Month\') AS month, monthSalary AS salary FROM driverSalary WHERE uid = $1 ORDER BY (year,month) DESC',
    cOrderInfo:   'SELECT cast(orderID as varchar) as orderID, to_char(date,\'DD-Mon-YYYY\') as date, to_char(timeorderplace, \'HH24:MI:SS\') as timeplace, location, deliveryduration, orderstatus, rating FROM Orders O JOIN Delivers D USING (orderID) WHERE D.uid = $1 and (O.orderstatus = \'Completed\' or O.orderstatus = \'Failed\') ORDER BY (EXTRACT(Year FROM O.date),EXTRACT(Month FROM O.date),EXTRACT(Day FROM O.date), O.timeOrderPlace) DESC',
    pOrderInfo:   'SELECT orderID as orderid, to_char(date,\'DD-Mon-YYYY\') as date, location, to_char(timeorderplace, \'HH24:MI:SS\') as timeplace,to_char(timedeparttorest, \'HH24:MI:SS\') as timetorest,to_char(timearriverest, \'HH24:MI:SS\') as timearrive,to_char(timedepartfromrest, \'HH24:MI:SS\') as timedepart,to_char(timeorderdelivered, \'HH24:MI:SS\') as timedelivered, orderstatus FROM Orders O JOIN Delivers D USING (orderID) WHERE D.uid = $1 and (O.orderstatus = \'Confirmed\' or O.orderstatus = \'Pending\') ORDER BY (EXTRACT(Year FROM O.date),EXTRACT(Month FROM O.date),EXTRACT(Day FROM O.date), O.timeOrderPlace) DESC',
    ftshedInfo:   'SELECT to_char(W.workDate,\'Mon-YYYY\') as period, to_char(W.workDate,\'DD-Mon-YYYY\') as wDate, S.shiftDetail1 as shifts1, S.shiftDetail2 as shifts2 FROM WorkingWeeks W JOIN ShiftOptions S USING (shiftID) WHERE uid = $1 ORDER BY (EXTRACT(Year FROM W.workDate),EXTRACT(Month FROM W.workDate),EXTRACT(Day FROM W.workDate)) DESC',
    ptshedInfo:   'SELECT to_char(workDate,\'Mon-YYYY\') as period, to_char(workDate,\'DD-Mon-YYYY\') as date, to_char(intervalStart, \'HH24:MI:SS\') as intervstart, to_char(intervalEnd, \'HH24:MI:SS\') as intervend FROM WorkingDays WHERE uid = $1 ORDER BY (EXTRACT(Year FROM workDate),EXTRACT(Month FROM workDate),EXTRACT(Day FROM workDate)) DESC',
    ftShiftInfo:  'SELECT * FROM ShiftOptions',

    statusUpdate:   'UPDATE Orders SET orderStatus = \'Completed\' WHERE orderID = $1',
    orderFailed:    'UPDATE Orders SET orderStatus = \'Failed\' WHERE orderID = $1',
    departtoUpdate: 'UPDATE Orders SET timeDepartToRest = NOW() WHERE orderID = $1',
    arriveUpdate:   'UPDATE Orders SET timeArriveRest = NOW() WHERE orderID = $1',
    departfrUpdate: 'UPDATE Orders SET timeDepartFromRest = NOW() WHERE orderID = $1',
    deliverUpdate:  'UPDATE Orders SET timeOrderDelivered = NOW() WHERE orderID = $1',
    durationUpate:  'UPDATE Orders SET deliveryduration = (SELECT to_char((timeOrderDelivered - timeOrderPlace), \'HH24 h MI \"min\"\') FROM Orders WHERE orderID = $1) WHERE orderID = $1',
    
    ftschedInsert:  'INSERT INTO WorkingWeeks(uid, workDate, shiftID) VALUES($1, $2, $3)',
    ptschedInsert:  'INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd) VALUES ($1, $2, $3, $4)',               

    /*------Customers--------*/
    custInfo: 'SELECT * FROM Customers WHERE uid = $1',
    updateUserCard: 'UPDATE Users SET cardDetails = $2 WHERE uid = $1',
    updateCustomerCard: 'UPDATE Customers SET cardDetails = $2 WHERE uid = $1',
    //orderInfo: 'SELECT distinct * FROM Place P JOIN Orders O USING (orderID) JOIN FromMenu F USING (orderID) JOIN Restaurants R USING (restaurantID) WHERE P.uid = $1',
    reviewInfo :'SELECT DISTINCT o.date as date, R.name, P.review, P.star FROM Place P JOIN Orders O USING (orderID) JOIN FromMenu USING (orderID) JOIN Restaurants R USING (restaurantID) WHERE P.uid = $1',
    orderInfo:'SELECT O.date::timestamp::date, R.name, F.foodName, F.quantity FROM Place P JOIN Orders O USING (orderID) JOIN FromMenu F USING (orderID) JOIN Restaurants R USING (restaurantID) WHERE P.uid = $1',


}

module.exports = sql;