	**
	**
	*FIGURES
	*
	* _____________________________________________________________________________________________________________________________________________________________ *
		
		
	**
	*Figure B1
	**
	**------------------------------------------------------------------------------------------------------------------------------------------------------------- *
	{
		use "$dtfinal/SE LIGA & Acelera_Recife.dta" if year >= 2010 & year <= 2018, clear
		
		foreach grade in 3 4 5  {
		    
			if `grade' == 3 {
			    local title = "Third-grade"
				local g     = "a"
			}	
			if `grade' == 4 {
				local g     = "b"
			}	
			if `grade' == 5 {
				local g 	= "c"
			}
			
			forvalues year = 2010(1)2015 {
				su 		distorcao 		if grade == `grade' & year == `year', detail
				replace distorcao = . 	if grade == `grade' & year == `year' & (distorcao <= r(p1) | distorcao >= r(p99))
			}
		
			tw ///
				histogram distorcao if type_program == 3 & grade == `grade', bin(30) fcolor(none) lcolor(dkorange*0.8)  lwidth(0.3)			///
			||  histogram distorcao if type_program == 1 & grade == `grade', bin(30) fcolor(none) lcolor(black)  lwidth(0.3)				///
			legend(order(1 "Acelera" 2 "Regular") cols(3) size(medium)  region(lwidth(white) lcolor(white) color(white) fcolor(white) )) 	///
			ytitle(, size(medsmall)) ylabel(, labsize(small) format(%12.1fc)) 						 		 	 							///
			xtitle("Age-grade distortion", size(medium)) xlabel(,labsize(medium) format(%12.0fc)) 												///
			title("", pos(12) size(medium) color(black)) 														 						///
			subtitle("", pos(12) size(medsmall) color(black)) 																				///
			graphregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 	 							///
			plotregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white))	 							///
			ysize(5) xsize(7) 																					 							///
			note("", color(black) fcolor(background) pos(7) size(vsmall)) 
			graph export "$figures/FigureB1`g'.pdf", as(pdf) replace	
		}
	}	
		
		
	**
	*Figure B2
	**
	**------------------------------------------------------------------------------------------------------------------------------------------------------------- *
	//The size of the classes SE LIGA/Acelera
	{
		use "$dtfinal/SE LIGA & Acelera_Recife.dta" if year >= 2010 & grade > 2 & grade < 6, clear
			
			forvalues year = 2010(1)2018 {
				su 		students_class		if  year == `year' & type_program == 1, detail
				replace students_class = .  if (year == `year' & type_program == 1)  & (students_class <= r(p1) | students_class > r(p95))  
				
				su 		students_class 		if  year == `year' & type_program >  1, detail
				replace students_class = .  if (year == `year' & type_program >  1)  & (students_class <= r(p1) | students_class > r(p95)) 
			}
		
			duplicates drop cd_turma codschool grade year, force
			bys type_program: su students_class if  year == 2018
			
				tw   histogram students_class if type_program == 1, bin(30) fcolor(none) lcolor(black) 															///
			||  	 histogram students_class if t_acelera 	 == 1, bin(30) fcolor(none) lcolor(dkorange*0.8) lw(0.6) 	 										///
			legend(order( 1 "Regular" 2 "Acelera") cols(3) size(medium)  region(lwidth(white) lcolor(white) color(white) fcolor(white) )) 		///
			ytitle(, size(medsmall)) ylabel(, labsize(small) format(%12.2fc)) 						 		 	 											///
			xtitle("Students per class", size(medium)) xlabel(,labsize(medium) format(%12.0fc)) 															///
			title("", pos(12) size(huge) color(black)) 														 												///
			subtitle("", pos(12) size(medsmall) color(black)) 																								///
			graphregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 	 											///
			plotregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white))	 											///
			ysize(5) xsize(7) 																					 											///
			note("", color(black) fcolor(background) pos(7) size(small)) 
			graph export "$figures/FigureB2.pdf", as(pdf) replace	
	}	
		
		
		
	**
	*Figure B3
	**
	**------------------------------------------------------------------------------------------------------------------------------------------------------------- *
	//Number of grades jumped by people with at least one year of age-grade distortion 
	{
		use 	"$dtfinal/SE LIGA & Acelera_Recife.dta" if grade > 2 & grade < 6 & distorcao > 1 & !missing(distorcao) & year > 2009 & year < 2015 & inlist(status, 1, 2, 3) & inlist(type_program, 1,3) , clear //& (pulou1_program3 ==  1 | pulou2_program3 == 1 | pulou1_program2 == 1 | pulou2_program2 == 1)
		//nao da para olhar para 2018 porque como a base de fluxo vai ate 2018 nao temos como saber o que aconteceu com aquele aluno (se pulou 1 ou 2 anos)
		gen 	id = 1
		tab 	type_program pulou2_program3 , mis
		
		gen 	pulou1 = 1 if pulou1_program3 == 1 | pulou1_program2 == 1 | pulou1_program1 == 1
		gen 	pulou2 = 1 if pulou2_program3 == 1 | pulou2_program2 == 1 | pulou2_program1 == 1
		gen 	outros 	   = status 	 == 2 | status 	        == 3
		
		collapse (sum)pulou1 pulou2 outros, by(type_program grade)
		

			graph pie pulou1 pulou2 outros , by(type_program grade, note("") legend(off) graphregion(color(white) lcolor(white) fcolor(white)) cols(3)) pie(1, explode  color(gs12)) pie(2, explode color(emidblue) )  pie(3, explode color(cranberry*0.80)) ///
				legend(off) 	 																												///
				plabel(_all percent,   						 gap(-20)  format(%2.0fc) size(small)) 												///
				plabel(1 "Jumped one grade",   				 gap(10)   format(%2.0fc) size(small))  												///
				plabel(2 "Jumped two grades",    			 gap(5)    format(%2.0fc) size(small)) 												///
				plabel(3 "Repeated/Dropped",    			 gap(10)   format(%2.0fc) size(small)) 												///
				graphregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white))	 					 		///
				plotregion(color(white)  fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 						 		///
				note("", span color(black) fcolor(background) pos(7) size(vsmall))																///
				ysize(6) xsize(12) 	
				graph export "$figures/FigureB3.pdf", as(pdf) replace	
		}
		
		

		
	**
	*Figure B4
	**
	**------------------------------------------------------------------------------------------------------------------------------------------------------------- *
	//Proficiency
	{
		use "$dtinter/Proficiência.dta" if grade < 12 , clear
		collapse (mean)prof* insuf*, by (grade year)
		format prof* insuf* %4.0fc
			foreach var of varlist insuf* {
				replace `var' = `var'*100
			}
			
			foreach grade in 3 5 {
				preserve
				if `grade' == 3 keep if year > 2010 & year < 2016 //third  grade has performance in Math and Portuguese from 2011 and 2015
				if `grade' == 2 keep if year > 2015 			  //second grade has performance starting in 2016
				
				if `grade' == 3 local g = "a"
				if `grade' == 5 local g = "b"
				
					twoway ///
					(bar  prof year 		if grade == `grade'	, barw(.5)  mlab(prof) mlabpos(12) mlabcolor(black) lcolor(navy) lwidth(0.2) fcolor(gs14) fintensity(inten60) yaxis(2)) 			 ///
				|| (scatter insuf_mat  year if grade == `grade' , symbol(O) color(emidblue*0.8)  msize(medsmall) ml(insuf_mat)  mlabcolor(black) mlabposition(9) mlabsize(2) yaxis(1))	 ///
				|| (scatter insuf_port year if grade == `grade' , symbol(O) color(cranberry*0.8) msize(medsmall) ml(insuf_port) mlabcolor(black) mlabposition(3) mlabsize(2) yaxis(1) 	 ///
					ysca(axis(1) r(0 80) line)     ylab(0(10)80, 	  angle(horizontal) labsize(small) format(%4.0f) axis(1)) 					 						 ///
					ysca(axis(2) r(3 6)  line)  ylab(3(0.5)6,     angle(horizontal) labsize(small) format(%4.1f) axis(2))		///
					legend(order(1 "Proficiency (Portuguese & Math)" 2 "% insufficient performance in Math" 3 "% insufficient performance in Portuguese" ) cols(2) size(medsmall) region(lwidth(none) color(none)) pos(6))  			 				/// 		
					title("", pos(12) size(medsmall) color(black)) 														///     
					ytitle("%", axis(1) size(small) color(black))														/// 
					ytitle("Proficiency (0-10)", axis(2) size(small) color(black)) 										///
					xtitle("", size(small))  																			///
					graphregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white))	///
					plotregion( color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 	///
					ysize(5) xsize(7)							 														///
					note("", span color(black) fcolor(background) pos(7) size(vsmall)))
					graph export "$figures/FigureB4`g'.pdf", as(pdf) replace	
				restore
			}
	}		


		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
	/**	
		
	{	//vemos que temos overlap de escolas com apenas educacao regular e escolas que oferecem Acelera
		use "$dtfinal/SE LIGA & Acelera_Recife.dta" if year < 2015, clear

		collapse (sum)dist_1mais dist_2mais, by(codschool year tipo_escola)
		
		foreach dist in 1 2 { 
		
			if `dist' == 1 {
			local title "one year"
			local fig   "a"
			
			}
			else {
			local title "two years"
			local fig "b"
			}
			
			su dist_`dist'mais, detail 
			local yu = r(max)
			
			
				tw ///
			||  histogram dist_`dist'mais if tipo_escola == 1, bin(30) fcolor(none) lcolor(black) 															///
			||  histogram dist_`dist'mais if inlist(tipo_escola, 3,4), bin(30) fcolor(none) lcolor(dkorange*0.8) lw(0.6) 	 								///
			legend(order(1 "Regular" 2 "Acelera") cols(3) size(medium)  region(lwidth(white) lcolor(white) color(white) fcolor(white) )) 					///
			xlabel(0(20)`yu') ///
			ytitle(, size(medsmall)) ylabel(, labsize(small) format(%12.2fc)) 						 		 	 											///
			xtitle("Students with at least `title' of age-grade distortion", size(medium)) xlabel(,labsize(medium) format(%12.0fc)) 						///
			title("", pos(12) size(huge) color(black)) 														 												///
			subtitle("", pos(12) size(medsmall) color(black)) 																								///
			graphregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 	 											///
			plotregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white))	 											///
			ysize(5) xsize(7) 																					 											///
			note("Source: Authors' estimate/EMPREL.", color(black) fcolor(background) pos(7) size(vsmall)) 
			graph export "$figures/figureA1`fig'.pdf", as(pdf) replace	
		}
	}
	**------------------------------------------------------------------------------------------------------------------------------------------------------------- *
	
	