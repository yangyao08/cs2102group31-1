/* ------ Compulsory Header ----- */
var express = require('express');
/* A router to handle requests of corressponding page with same name*/
var router = express.Router();
/*for page authentication.*/
const passport = require('passport');
/*Modules for database interaction*/
const sql = require('../db/dbsql');
const caller = require('../db/dbcaller');

restId = null;
id_rest = 0;
var OrderInfo = [];
var totalPrice = 0;
var minThreshold = 0;
var rewardPts = null;

var dates = {
	convert: function (d) {
		// Converts the date in d to a date-object. The input can be:
		//   a date object: returned without modification
		//  an array      : Interpreted as [year,month,day]. NOTE: month is 0-11.
		//   a number     : Interpreted as number of milliseconds
		//                  since 1 Jan 1970 (a timestamp) 
		//   a string     : Any format supported by the javascript engine, like
		//                  "YYYY/MM/DD", "MM/DD/YYYY", "Jan 31 2009" etc.
		//  an object     : Interpreted as an object with year, month and date
		//                  attributes.  **NOTE** month is 0-11.
		return (
			d.constructor === Date ? d :
				d.constructor === Array ? new Date(d[0], d[1], d[2]) :
					d.constructor === Number ? new Date(d) :
						d.constructor === String ? new Date(d) :
							typeof d === "object" ? new Date(d.year, d.month, d.date) :
								NaN
		);
	},
	compare: function (a, b) {
		// Compare two dates (could be of any type supported by the convert
		// function above) and returns:
		//  -1 : if a < b
		//   0 : if a = b
		//   1 : if a > b
		// NaN : if a or b is an illegal date
		// NOTE: The code inside isFinite does an assignment (=).
		return (
			isFinite(a = this.convert(a).valueOf()) &&
				isFinite(b = this.convert(b).valueOf()) ?
				(a > b) - (a < b) :
				NaN
		);
	},
	inRange: function (d, start, end) {
		// Checks if date in d is between dates in start and end.
		// Returns a boolean or NaN:
		//    true  : if d is between start and end (inclusive)
		//    false : if d is before start or after end
		//    NaN   : if one or more of the dates is illegal.
		// NOTE: The code inside isFinite does an assignment (=).
		return (
			isFinite(d = this.convert(d).valueOf()) &&
				isFinite(start = this.convert(start).valueOf()) &&
				isFinite(end = this.convert(end).valueOf()) ?
				start <= d && d <= end :
				NaN
		);
	}
}

function custInfo(req, res, next) {
	caller.query(sql.query.custInfo, [req.user.uid], (err, data) => {
		if (err) {
			return next(err);
		}
		rewardPts = data.rows[0].rewardpts;
		return next();
	});
}

function restInfo(req, res, next) {
	caller.query(sql.query.restInfo, (err, data) => {
		if (err) {
			return next(err);
		}
		req.restInfo = data.rows;
		return next();
	});
}

function avgRating(req, res, next) {
	caller.query(sql.query.avgRating, [restId], (err, data) => {
		if (err) {
			req.avgRating = null;
			return next(err);
		}
		req.avgRating = data.rows[0].avg;
		return next();
	});
}

function reviewInfo(req, res, next) {
	caller.query(sql.query.restReview, [restId], (err, data) => {
		if (err) {
			return next(err);
		}
		req.reviewInfo = data.rows;
		return next();
	});
}

function menuInfo(req, res, next) {
	caller.query(sql.query.menuInfo, [restId], (err, data) => {
		if (err) {
			return next(err);
		}
		req.menuInfo = data.rows;
		return next();
	});
}

function paymentInfo(req, res, next) {
	caller.query(sql.query.paymentInfo, (err, data) => {
		if (err) {
			return next(err);
		}
		req.paymentInfo = data.rows;
		return next();
	});
}

function promoInfo(req, res, next) {
	console.log(id_rest);
	caller.query(sql.query.promo, [id_rest], (err, data) => {
		if (err) {
			return next(err);
		}
		req.promoInfo = data.rows;
		return next();
	});
}

function addrInfo(req, res, next) {
	console.log(id_rest);
	caller.query(sql.query.addrInfo, [req.user.uid], (err, data) => {
		if (err) {
			return next(err);
		}
		req.addrInfo = data.rows;
		return next();
	});
}

function loadPage(req, res, next) {
	res.render('cust_menu', {
		restInfo: req.restInfo,
		reviewInfo: req.reviewInfo,
		avgRating: req.avgRating,
		menuInfo: req.menuInfo,
		orderInfo: OrderInfo,
		paymentInfo: req.paymentInfo,
		totalPrice: totalPrice,
		minThreshold: minThreshold,
		promoInfo: req.promoInfo,
		addrInfo: req.addrInfo,
		rewardPts: rewardPts
	});
}

router.get('/', passport.authMiddleware(), custInfo, restInfo, avgRating, reviewInfo, menuInfo, paymentInfo, promoInfo, addrInfo, loadPage);

router.post('/getRest', function (req, res, next) {
	restId = req.body.restName;
	console.log(restId);
	// to prevent cust from adding order from different rest...
	OrderInfo = [];
	totalPrice = 0;

	caller.query(sql.query.menuInfo, [restId], (err, data) => {
		if (err) {
			return next(err);
		}
		id_rest = Number(data.rows[0].restaurantid);
		minThreshold = Number(data.rows[0].minthreshold);
		console.log(minThreshold + " = min");
		console.log(id_rest + " = id");
	});

	res.redirect('/cust_menu');
});

// this one is kinda complicated -.- 
router.post('/addOrder', function (req, res, next) {
	var promo_info = req.body.promo;
	var promo_per = 1; // defoult no promo
	var promo_amt = 0; // default no promo
	//var id_rest = null;
	var d = new Date();
	if (promo_info == '-') {
		promo_info = null;
		caller.query(sql.query.addfoodper, [req.body.orderItem, restId, req.body.orderAmount, promo_per, promo_info], (err, data) => {
			if (err) {
				return next(err);
			}
			OrderInfo.push(data.rows[0]);
			totalPrice += Number(data.rows[0].price);
		});
	} else {

		// check for valid promo code
		caller.query(sql.query.promoD, [promo_info], (err, data) => {
			if (err) {
				return next(err);
			}
			promo_per = data.rows[0].discperc;
			promo_amt = data.rows[0].discamt;

			console.log(promo_per);
			console.log(promo_amt);

			time = (d.toTimeString()).substring(0, 8);

			// check for valid promo code
			if (!dates.inRange(d, data.rows[0].startdate, data.rows[0].enddate)) {
				// do nothing 
				console.log("datefail")
			} else if (data.rows[0].endtime < time) {
				// do nothing	
				console.log("timefail")
			}
			else {
				if (promo_amt == null) {
					promo_per = 1 - promo_per;
					console.log(promo_per);

					// without checking time yet ...
					caller.query(sql.query.addfoodper, [req.body.orderItem, restId, req.body.orderAmount, promo_per, promo_info], (err, data) => {
						if (err) {
							return next(err);
						}
						OrderInfo.push(data.rows[0]);
						totalPrice += Number(data.rows[0].price);
					});
				} else if (promo_per == null) {
					caller.query(sql.query.addfoodamt, [req.body.orderItem, restId, req.body.orderAmount, promo_amt, promo_info], (err, data) => {
						if (err) {
							return next(err);
						}
						OrderInfo.push(data.rows[0]);
						totalPrice += Number(data.rows[0].price);
					});
				}
			}
		});
	}
	res.redirect('/cust_menu');
});

router.post('/cfmOrder', function (req, res, next) {
	if (minThreshold > totalPrice) {
		//do nothing 
	} else if (totalPrice > rewardPts) {
		//do nothing
	} else {
		var addr = null;
		var area = req.body.area;
		var payopt = req.body.paytype;
		var orderID = null;
		totalPrice += 4;


		if (req.body.pastAddr == "null") {
			addr = req.body.newAddr;
		} else {
			addr = req.body.pastAddr;
		}

		if (payopt == "RewardPts") {
			console.log ("I pay by rewardpts");
			console.log (totalPrice);
			console.log (rewardPts);
			var newpts = Math.round(rewardPts - totalPrice);
			caller.query(sql.query.payReward, [req.user.uid, newpts], (err, data) => {
				if (err) {
					return next(err);
				}
				console.log("successfully deduct reward pts");
			});
		}

		caller.query(sql.query.insertOrder, [addr, payopt, area, totalPrice], (err, data) => {
			if (err) {
				return next(err);
			}

			orderID = data.rows[0].orderid;

			for (i = 0; i < OrderInfo.length; i++) {
				console.log(orderID);
				caller.query(sql.query.insertFM, [OrderInfo[i].promoid, OrderInfo[i].amount, orderID, OrderInfo[i].restaurantid, OrderInfo[i].foodname], (err, data) => {
					if (err) {
						return next(err);
					}
					console.log("successfully added from menu");
				})
			}


			caller.query(sql.query.insertPlace, [orderID, req.user.uid], (err, data) => {
				if (err) {
					return next(err);
				}
				console.log("successfully added place");
			})
		});
	}

	 res.redirect('/cust_orderInfo');
});


module.exports = router;