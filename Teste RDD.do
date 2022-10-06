 
 
	 use "$dtfinal/SE LIGA & Acelera_Recife.dta" if grade == 5 & el1_5ano == 1, clear

	 
	 
		collapse (mean) prof_LP prof_MT nalunos_dist_1mais, by(codschool acelera_school year) 
 
			merge 1:1 codschool year using "$dtinter/School Level Data.dta"
 
 
 	   keep if inrange(year, 2011, 2015)
						
						gen 	running_var = ( nalunos_dist_1mais - 9 ) if year == 2011
						replace running_var = (nalunos_dist_1mais- 13) if year == 2012
						replace running_var = ( nalunos_dist_1mais - 21) if year == 2013
						replace running_var = ( nalunos_dist_1mais- 29) if year == 2014
						replace running_var = ( nalunos_dist_1mais- 18) if year == 2015	
				
						gen D = running_var >= 0

					*keep if running_var <= 20 
				*	keep if year == 2011
					tw  (lpolyci prof_LP running_var if running_var >= 0 , kernel(triangle) degree(0) bw(4) acolor(gs12) fcolor(gs12) clcolor(gray) clwidth(0.3)) 		///
					(lpolyci prof_LP running_var  if running_var <  0, kernel(triangle) degree(0) bw(4) acolor(gs12) fcolor(gs12) clcolor(gray) clwidth(0.3)) 		///
					(scatter prof_LP running_var  if running_var <  0 ,  sort msymbol(circle) msize(small) mcolor(navy))         		 	///
					(scatter prof_LP running_var  if running_var >=   0 ,  sort msymbol(circle) msize(small) mcolor(cranberry)), xline(0) 	///
					legend(off) 																									///
					plotregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 				///						
					ytitle("%") xtitle("Age difference from the cutoff (in weeks)", size(small))  	/// 
					note("", color(black) fcolor(background) pos(7) size(small)) 


 
 
						ivregress  2sls  prof_MT (proporca_acelera = D) running_var ScienceLab ClosedSportCourt Library ReadingRoom InternetAccess SportCourt OwnBuilding i.year , cluster(codschool)

 
 
 
 
				
			use	"$dtinter/School Level Data.dta", clear
			
				    keep if inrange(year, 2011, 2015)
						
						gen 	running_var = (alunos_1mais - 9 ) if year == 2011
						replace running_var = (alunos_1mais- 13) if year == 2012
						replace running_var = (alunos_1mais - 21) if year == 2013
						replace running_var = (alunos_1mais- 29) if year == 2014
						replace running_var = (alunos_1mais- 18) if year == 2015	
				
						gen D = running_var >= 0

					keep if running_var <= 20 
					keep if year == 2011
					tw  (lpolyci prof_LP_stand5t running_var if running_var >= 0 & running_var <= 80, kernel(triangle) degree(0) bw(4) acolor(gs12) fcolor(gs12) clcolor(gray) clwidth(0.3)) 		///
					(lpolyci prof_LP_stand5t running_var  if running_var <  0, kernel(triangle) degree(0) bw(4) acolor(gs12) fcolor(gs12) clcolor(gray) clwidth(0.3)) 		///
					(scatter prof_LP_stand5t running_var  if running_var <  0 ,  sort msymbol(circle) msize(small) mcolor(navy))         		 	///
					(scatter prof_LP_stand5t running_var  if running_var >=   0 & running_var <= 80,  sort msymbol(circle) msize(small) mcolor(cranberry)), xline(0) 	///
					legend(off) 																									///
					plotregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 				///						
					ytitle("%") xtitle("Age difference from the cutoff (in weeks)", size(small))  	/// 
					note("", color(black) fcolor(background) pos(7) size(small)) 

					
					
					
										
									
									
									
									
									
									
									
				
	use "$dtfinal/SE LIGA & Acelera_Recife.dta" if grade == 5, clear
				
	tab year t_acelera if prof_LP_stand != .
	tab year  t_acelera
 
 
 	global schoolinfra EnergyAccess SewerAccess WaterAccess Computer Library ComputerLab ScienceLab SportCourt InternetAccess SchoolEmployees BroadBandInternet
 
 
					 use "$dtfinal/SE LIGA & Acelera_Recife.dta" if grade == 5, clear
						
						
					    keep if inrange(year, 2011, 2015)
						
						gen 	running_var = (nalunos_dist_1mais - 9 ) if year == 2011
						replace running_var = (nalunos_dist_1mais - 13) if year == 2012
						replace running_var = (nalunos_dist_1mais - 21) if year == 2013
						replace running_var = (nalunos_dist_1mais - 29) if year == 2014
						replace running_var = (nalunos_dist_1mais - 18) if year == 2015
						
						gen D = running_var >= 0
						 
						 keep if el1_5ano ==  1
											
						gen running_var2 = running_var*running_var 
						drop if running_var2 < 70
						ivregress  2sls  prof_LP_stand  (t_acelera = D) running_var running_var2 i.gender students_class dif_idade_turma distorcao $schoolinfra i.year , cluster(codschool)
				
				
				
				
				
				
				
				
				
					use "$dtfinal/SE LIGA & Acelera_Recife.dta" if grade == 5, clear
						
						
						
					    keep if inrange(year, 2011, 2015)
						
						gen 	running_var = (nalunos_dist_1mais - 9 ) if year == 2011
						replace running_var = (nalunos_dist_1mais - 13) if year == 2012
						replace running_var = (nalunos_dist_1mais - 21) if year == 2013
						replace running_var = (nalunos_dist_1mais - 29) if year == 2014
						replace running_var = (nalunos_dist_1mais - 18) if year == 2015
						
						gen D = running_var >= 0
						
						
						foreach year in 2011 2012 2013 2014 2015 {
							preserve
							keep if year == `year'
							keep if el1_5ano == 1
							psmatch2  D distorcao i.status_anterior gender dif_idade_turma , n(3) common ties
							keep 		if _support == 1						
							keep 		if _weight != .
							duplicates 	drop cd_mat, force
							keep 			cd_mat _weight year
							tempfile  	   `year'
							save          ``year''
							restore
						}
						
						preserve
						clear
						foreach year in 2011 2012 2013 2014 2015 {
							
							append using  ``year''
	
						}
						restore
						
						tempfile matching
						save `matching'

						
						
						merge 1:1 cd_mat year using `matching', keep(3)
						
						
																	
						gen running_var2 = running_var*running_var 
					*	drop if running_var2 < 70
						ivregress  2sls  prof_LP_stand  (t_acelera = D) running_var running_var2 i.gender students_class dif_idade_turma distorcao $schoolinfra i.year , cluster(codschool)

					tw  (lpolyci prof_LP_stand running_var if running_var >= 0 & running_var <= 80, kernel(triangle) degree(0) bw(4) acolor(gs12) fcolor(gs12) clcolor(gray) clwidth(0.3)) 		///
					(lpolyci prof_LP_stand running_var  if running_var <  0, kernel(triangle) degree(0) bw(4) acolor(gs12) fcolor(gs12) clcolor(gray) clwidth(0.3)) 		///
					(scatter prof_LP_stand running_var  if running_var <  0 ,  sort msymbol(circle) msize(small) mcolor(navy))         		 	///
					(scatter prof_LP_stand running_var  if running_var >=   0 & running_var <= 80,  sort msymbol(circle) msize(small) mcolor(cranberry)), xline(0) 	///
					legend(off) 																									///
					plotregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 				///						
					title({bf:`: variable label `var''}, pos(11) color(navy) span size(medium))										///
					ytitle("%") xtitle("Age difference from the cutoff (in weeks)", size(small))  	/// 
					note("", color(black) fcolor(background) pos(7) size(small)) 

				
				
				
				
				
				
				
					use "$dtfinal/SE LIGA & Acelera_Recife.dta" if grade == 5 & el1_5ano == 1 & year == 2011, clear
						
						gen 	running_var = (nalunos_dist_1mais - 9) 
						
						gen D = running_var >= 0
						keep if running_var <= 80
				
																	
						gen running_var2 = running_var*running_var 

					tw  (lpolyci prof_LP_stand running_var if running_var >= 0 & running_var <= 80, kernel(triangle) degree(0) bw(4) acolor(gs12) fcolor(gs12) clcolor(gray) clwidth(0.3)) 		///
					(lpolyci prof_LP_stand running_var  if running_var <  0, kernel(triangle) degree(0) bw(4) acolor(gs12) fcolor(gs12) clcolor(gray) clwidth(0.3)) 		///
					(scatter prof_LP_stand running_var  if running_var <  0 ,  sort msymbol(circle) msize(small) mcolor(navy))         		 	///
					(scatter prof_LP_stand running_var  if running_var >=   0 & running_var <= 80,  sort msymbol(circle) msize(small) mcolor(cranberry)), xline(0) 	///
					legend(off) 																									///
					plotregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 				///						
					ytitle("%") xtitle("Age difference from the cutoff (in weeks)", size(small))  	/// 
					note("", color(black) fcolor(background) pos(7) size(small)) 

					
					
					
					
					
									*	drop if running_var2 < 70
						ivregress  2sls  prof_LP_stand  (t_acelera = D) running_var running_var2 i.gender students_class dif_idade_turma distorcao $schoolinfra i.year , cluster(codschool)

				
				
				
