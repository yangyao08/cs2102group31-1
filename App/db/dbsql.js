const sql = {}


sql.query = {

    //Login
    login: 'SELECT * FROM Users WHERE username=$1',

    //Restaurant Staff
    restInfo: 'SELECT * FROM Restaurants R INNER JOIN RestaurantStaff RS on R.restaurantID =  RS.restaurantID WHERE RS.uid = $1',
    menuInfo: 'SELECT * FROM Food F INNER JOIN Restaurants R on F.restaurantID = R.restaurantID INNER JOIN RestaurantStaff RS on R.restaurantID =  RS.restaurantID WHERE RS.uid = $1',

    //Guide_files
    all_users: 'SELECT uid, name, username FROM Users',
    insert_customer: 'INSERT INTO Users(name, username, password, type) Values($1, $2, $3, \'Customers\')'


}

module.exports = sql;