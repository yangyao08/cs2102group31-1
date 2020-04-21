/* ------ Compulsory Header ----- */
var express = require('express');
/* A router to handle requests of corressponding page with same name*/
var router = express.Router();
/*for page authentication*/
const passport = require('passport');
/*Modules for database interaction*/ 
const sql = require('../db/dbsql');
const caller = require('../db/dbcaller');

//Global variable to store restID
var uuid = null;

function ftshedInfo(req, res, next) {
	/*----- IMPT: Stuff in [] is for your sql parameters ($) ----- */
	caller.query(sql.query.ftshedInfo, [req.user.uid], (err, data) => {
        if(err){
            return next(error);
        }
		req.ftshedInfo = data.rows;
		uuid = req.user.uid;
        return next();
	});
}

function ftShiftInfo(req, res, next) {
	/*----- IMPT: Stuff in [] is for your sql parameters ($) ----- */
	caller.query(sql.query.ftShiftInfo, (err, data) => {
        if(err){
            return next(error);
        }
		req.ftShiftInfo = data.rows;
        return next();
	});
}

function loadPage(req, res, next) {
	/*-- IMPT: How to send data to your frontend ejs file --- */
	res.render('rider_ftschedule',{
		username:req.user.username, 
		name:req.user.name,
		type:req.user.ridertype,
		ftshedInfo: req.ftshedInfo,
		ftShiftInfo: req.ftShiftInfo
	});
}


/* USEFUL: passport.authMiddleware() make sure user is autheticated before accessing page*/
router.get('/', passport.authMiddleware(), ftshedInfo, ftShiftInfo, loadPage);

router.post('/addschedule', function(req, res, next) {
	//from <form> in ejs file
	var day1 = new Date(req.body.day1);
	var day2 = new Date(req.body.day1);
	var day3 = new Date(req.body.day1);;
	var day4 = new Date(req.body.day1);
	var day5 = new Date(req.body.day1);
	day2.setDate(day2.getDate()+1);
	day3.setDate(day3.getDate()+2);
	day4.setDate(day4.getDate()+3);
	day5.setDate(day5.getDate()+4);

	var s1  = req.body.s1;
	var s2  = req.body.s2;
	var s3  = req.body.s3;
	var s4  = req.body.s4;
	var s5  = req.body.s5;

	const shouldAbort = err => {
		if (err) {
		console.error('Error in transaction', err.stack)
		caller.query('ROLLBACK', err => {
			if (err) {
			console.error('Error rolling back client', err.stack)
			}
		})
		}
	}

	caller.query('BEGIN',err=>{
		if (shouldAbort(err)) return

		caller.query(sql.query.ftschedInsert,[uuid, day1, s1], (err, data) =>{
			if (shouldAbort(err)) return

			caller.query(sql.query.ftschedInsert,[uuid, day2, s2], (err, data) =>{
				if (shouldAbort(err)) return

				caller.query(sql.query.ftschedInsert,[uuid, day3, s3], (err, data) =>{
					if (shouldAbort(err)) return

					caller.query(sql.query.ftschedInsert,[uuid, day4, s4], (err, data) => {
						if (shouldAbort(err)) return

						caller.query(sql.query.ftschedInsert,[uuid, day5, s5], (err, data) =>{
							if (shouldAbort(err)) return

							caller.query('COMMIT', err=>{
								if(err){
									console.error("Error in adding schedule",err.stack)
								}
								res.redirect('/rider_ftschedule');
							})
						}) 
					})
				})
			})
		})
	})

});


module.exports = router;