
**
**
*Decriptives used mentioned in the paper
*
* _____________________________________________________________________________________________________________________________________________________________ *
	
	
	**
	*Age distortion of 1st to 5th grade
	**--------------------------------------------------------------------------------------------------------------------------------------------------------- *
	{
	use "$distorcao/Age Distortion at municipal level.dta"				if network == 3 & location == 3 , clear

		br 					if codmunic == 2611606 		//in Recife. 
	}
	
	
	**
	*Jump in repetition from 2nd to 3rd grade
	**--------------------------------------------------------------------------------------------------------------------------------------------------------- *
	{
	use "$rendimento/Flow Indicators at municipal level.dta" 			if network == 3 & location == 3 , clear

		br year repetition* if codmunic == 2611606 		//in Recife. 
	}	
	
	
	**
	*Share of students from 3rd to 5th grade among the treated ones
	**--------------------------------------------------------------------------------------------------------------------------------------------------------- *
	{
	**
	*Se Liga e Acelera
		use 	"$dtfinal/SE LIGA & Acelera_Recife.dta" 	, clear
			forvalues 	year = 2010(1)2014 {
				quietly {
					**
					count 	if (type_program == 2 | type_program == 3) & 			  grade <= 5 & year == `year'		//todos participantes
					local   part = r(N)
					
					**
					count 	if (type_program == 2 | type_program == 3) & grade >= 3 & grade <= 5 & year == `year'		//participantes do 3o ao 5o ano
				}
				**
				di 		as red 		"`year'"
				di	 	as white 	`r(N)'/`part'				// a maior parte dos alunos participantes da intervencoes estao matriculados do 3o ao 5o ano. 
			}
			
	**
	*Acelera
		use 	"$dtfinal/SE LIGA & Acelera_Recife.dta" 	, clear
			forvalues 	year = 2010(1)2014 {
				quietly {
					**
					count 	if (type_program == 3) & 			  grade <= 5 & year == `year'
					local   part = r(N)
					
					**
					count 	if (type_program == 3) & grade >= 3 & grade <= 5 & year == `year'
				}
				**
				di 		as red 		"`year'"
				di	 	as white 	`r(N)'/`part'				// a maior parte dos alunos participantes da intervencoes estao matriculados do 3o ao 5o ano. 
			}
	}		
			
		
	**
	*Grade and program enrolled
	**--------------------------------------------------------------------------------------------------------------------------------------------------------- *
	{
	use 	"$dtfinal/SE LIGA & Acelera_Recife.dta" if type_program == 2 | type_program == 3, clear
	
		forvalues 	year = 2010(1)2014 {
				tab 	grade type_program if year == `year'
		}
	}		

		
	**
	*Age distortion of the participants
	**--------------------------------------------------------------------------------------------------------------------------------------------------------- *
	{
		use "$dtfinal/SE LIGA & Acelera_Recife.dta" 				, clear
		
			su  distorcao  if (type_program == 3) & grade < 6 	, detail
		
			tab dist_1mais if (type_program == 2 | type_program == 3) & year == 2010, 		// a maior parte dos incluidos tb apresenta pelo menos um ano de distorcao idade serie
			
			tab dist_1mais if (type_program == 2 | type_program == 3) & year == 2014, 
	}
	

	**
	*Numero de escolas oferecendo o programa por ano
	**--------------------------------------------------------------------------------------------------------------------------------------------------------- *
	{
	use "$dtinter/School Level Data.dta", clear
		tab 	year tipo_escola	
		codebook codschool if tem_acelera== 1
		codebook codschool
	}
	
	
	**
	*Number of participants
	**--------------------------------------------------------------------------------------------------------------------------------------------------------- *
	{
		use "$dtfinal/SE LIGA & Acelera_Recife.dta" 	, clear
		
			tab grade if type_program == 2 & inrange(grade, 3, 5)
			tab grade if type_program == 3 & inrange(grade, 3, 5)
			tab grade if type_program == 2 & inrange(grade, 1, 5)
			tab grade if type_program == 3 & inrange(grade, 1, 5)
			codebook cd_mat if type_program == 3 //num de estudantes beneficiados com Acelera. 
			
			codebook cd_mat if distorcao > 1 & !missing(distorcao)
			
			
	}	

	
	**
	*% of observations with missing status
	**--------------------------------------------------------------------------------------------------------------------------------------------------------- *
	{
		use "$dtfinal/SE LIGA & Acelera_Recife.dta" 	, clear
		
		tab year status, mis
		
	}		
		
		
	**
	*% of students in Acelera that have participated of Acelera
	**--------------------------------------------------------------------------------------------------------------------------------------------------------- *
	{
		use "$dtfinal/SE LIGA & Acelera_Recife.dta" if type_program == 3, clear //students currently enrolled in ACELERA
			tab ja_participou_seliga	
	}	
		
		
	**
	*Only a small number of cases in which the students participate of the interventions more than once
	**--------------------------------------------------------------------------------------------------------------------------------------------------------- *
	{	
		use "$dtfinal/SE LIGA & Acelera_Recife.dta" if none2018 == 0 //students that already participated of SE Liga/Acelera
		duplicates drop cd_mat, force
		
		tab num_parti_acelera if acelera2018 == 1					//number of times they were included in ACELERA
		tab num_parti_seliga  if seliga2018  == 1					//number of times they were included in SELIGA
	}
		

				
	**
	*Students joining the locally-managed network in fourth grade or leaving the network in fifth grade. 
	**--------------------------------------------------------------------------------------------------------------------------------------------------------- *
	{	
		use "$dtfinal/SE LIGA & Acelera_Recife.dta" if year > 2009, clear  //students that already participated of SE Liga/Acelera
		
		gen 	entrou_agora = 1 if grade == 4 & primeiro_ano_painel == year
		
		sort 	cd_mat year
		
		gen 	saiu_5ano    = 1 if grade == 4 & proxima_serie == . 
		
		gen id = 1 if grade == 4
		
		keep if grade == 4
		
		collapse (sum) id entrou_agora saiu_5ano, 
		
		gen p = (entrou_agora + saiu_5ano)/id
		
		
	}
	
	
	**
	*Students without a status
	**--------------------------------------------------------------------------------------------------------------------------------------------------------- *
	{	
		
	use "$dtfinal/SE LIGA & Acelera_Recife.dta" , clear  //students that already participated of SE Liga/Acelera
	
	tab year status
	}
	
	 use "C:\Users\wb495845\OneDrive - WBG\III. Labor\child-labor-ban-brazil\DataWork\Datasets\Intermediate\Pooled_PNAD.dta", clear
	 
	 keep if age >= 7 & age <= 11 & year == 1997 
	 
	 
	
		
		
	**
	*Flow indicators in Recife
	**--------------------------------------------------------------------------------------------------------------------------------------------------------- *
	{	
		use "$rendimento/Flow Indicators at municipal level.dta" if (year == 2009 | year == 2019) & network == 3 & codmunic == 2611606 , clear
		bys year: su repetitionEF1 
		bys year: su approvalEF1
		bys year: su dropoutEF1	


		use "$rendimento/Flow Indicators at municipal level.dta" if (				year == 2019) & network == 3 & codmunic == 2611606 , clear
		su repetition1grade			
		su repetition2grade			
		su repetition3grade			
		su repetition4grade		
		su repetition5grade			
	}	
		
		

	* --------------------------------------------------------------------------------------------------------------------------------------------------------- *
	**
	**
	*Performance and flow indicators: comparing Recife with the rest of the Pernambuco
	* --------------------------------------------------------------------------------------------------------------------------------------------------------- *
	{
		use 	"$distorcao/Age Distortion at municipal level.dta", clear
		**
		merge 	1:1 codmunic network year location using "$rendimento/Flow Indicators at municipal level.dta", nogen
		keep 	if location == 3 & network == 3
		
		**
		merge 	1:1 codmunic year network using "$ideb/IDEB at municipal level.dta", keep (1 3) 
		
		**
		expand 	2, gen(REP)
		gen 	agreg = "Brasil" 		if REP == 1
		replace agreg = "Recife"  		if codmunic == 2611606 				 & REP == 0
		replace agreg = "Pernambuco"    if codmunic != 2611606 & uf == "PE"	 & REP == 0
		keep if !missing(agreg)
		
		**
		collapse (mean)age* repetition* dropout* idebEF1 port5 math5 if year > 2008, by(year agreg)
		format dropout* %2.1fc
		format age* repetition* ideb* port* math* %2.0fc
		
		foreach var of varlist agedistortionEF1 repetitionEF1 dropoutEF1 idebEF1 port5 math5 {
			if "`var'" == "agedistortionEF1" {
				local min = 10
				local max = 30
			}
			if "`var'" == "repetitionEF1" {
				local min = 5
				local max = 15
			}
			if "`var'" == "dropoutEF1" {
				local min = 0
				local max = 3
			}
			
			if "`var'" == "idebEF1" {
				local min = 3
				local max = 7
			}
			
			if "`var'" == "port5" | "`var'" == "math5" {
				local min = 150
				local max = 250
			}
		
			twoway ///
			(line  `var' year if agreg == "Recife", 		msymbol(d) msize(small) lwidth(0.1)  color(cranberry) 		 lp(solid) 	   connect(direct) recast(connected) mlab(`var') mlabpos(6)  mlabcolor(black)) 	///
			(line  `var' year if agreg == "Pernambuco",  	msymbol(t) msize(small) lwidth(0.1)  color(cranberry*0.5)    lp(shortdash) connect(direct) recast(connected) mlab(`var') mlabpos(11) mlabcolor(black))  ///
			(line  `var' year if agreg == "Brasil", 				   msize(small) lwidth(0.1)  color(emidblue%70)	     lp(shortdash) connect(direct) recast(connected) mlab(`var') mlabpos(12) mlabcolor(black) 	///
			ysca(range(`min' `max') off)  xlabel(2009(1)2019, labsize(small) gmax angle(horizontal)) 											///
			ytitle("%", size(medsmall)) xtitle("", size(medsmall))												///
			ysize(5) xsize(5) 																					///
			legend(order(1 "Recife" 2 "Pernambuco" 3 "Brazil") region(lwidth(none) lcolor(none) fcolor(none)) cols(3) size(large) position(6)) 	///
			graphregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 	///
			plotregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 	///
			note("Source: School Census/INEP.", color(black) fcolor(background) pos(7) size(small))) 
			*graph export "$figures/`var'.pdf", as(pdf) replace	
		}
	}


	* --------------------------------------------------------------------------------------------------------------------------------------------------------- *
	**
	**
	*Age distortion by grade 
	* --------------------------------------------------------------------------------------------------------------------------------------------------------- *
	{
		use "$distorcao/Age Distortion at municipal level.dta" if network == 3 & codmunic == 2611606 & location == 3 & (year == 2011 | year == 2013 | year == 2015 | year == 2017 | year == 2019), clear
		graph bar (asis) agedistortion1grade agedistortion3grade agedistortion5grade, bargap(-30) bar(1, lcolor(red) lwidth(0.2) fcolor(red) fintensity(inten50)) 	 bar(2,  lwidth(0.2) fcolor(emidblue) fintensity(inten70)) bar(3, lcolor(navy) lwidth(0.2) fcolor(navy) fintensity(inten80))			///
			over(year, sort() label(labsize(small)))																						///
			blabel(bar, position(outside) orientation(horizontal) size(medium) color(black) format (%4.0fc))   								///
			title("", pos(12) size(medsmall) color(black)) subtitle(, pos(12) size(medsmall) color(black)) 									///
			ytitle(, size(medsmall)) yscale(r(10 50) off) ylabel(none)  																	///
			legend(order(1 "1{sup:st} grade" 2 "3{sup:rd} grade" 3 "5{sup:th} grade" ) region(lwidth(white) color(white) lcolor(white) fcolor(white)) cols(3) size(large) position(12))      		            		///
			note("Source: School Census/INEP." , color(black) fcolor(background) pos(7) size(small)) 										///
			graphregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 								///
			plotregion( color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 								///
			ysize(5) xsize(5) 	
			local nb =`.Graph.plotregion1.barlabels.arrnels'
			forval i = 1/`nb' {
				 di "`.Graph.plotregion1.barlabels[`i'].text[1]'"
				 .Graph.plotregion1.barlabels[`i'].text[1]="`.Graph.plotregion1.barlabels[`i'].text[1]'%"
			}
			.Graph.drawgraph
			graph export "$figures/age_distortion_by_grade.pdf", as(pdf) replace		
	}
		
		
	* --------------------------------------------------------------------------------------------------------------------------------------------------------- *
	**
	**
	*Repetition by grade
	* --------------------------------------------------------------------------------------------------------------------------------------------------------- *
	{
		use "$rendimento/Flow Indicators at municipal level.dta" if network == 3 & codmunic == 2611606 & location == 3 & (year == 2011 | year == 2013 | year == 2015 | year == 2017 | year == 2019), clear
		graph bar (asis) repetition2grade repetition3grade , bargap(-10) bar(1, lcolor(black) lwidth(0.2) fcolor(gs14))  bar(2,  lwidth(0.2) fcolor(emidblue) fintensity(inten70)) bar(3, lcolor(navy) lwidth(0.2) fcolor(navy) fintensity(inten80))			///
			over(year, sort() label(labsize(small)))																						///
			blabel(bar, position(outside) orientation(horizontal) size(medium) color(black) format (%4.0fc))   								///
			title("", pos(12) size(medsmall) color(black)) subtitle(, pos(12) size(medsmall) color(black)) 									///
			ytitle(, size(medsmall)) yscale(r(10 50) off) ylabel(none)  																	///
			legend(order(1 "2{sup:nd} grade" 2 "3{sup:rd} grade" ) region(lwidth(white) color(white) lcolor(white) fcolor(white)) cols(3) size(large) position(12))      		            		///
			note("Source: School Census/INEP." , color(black) fcolor(background) pos(7) size(small)) 										///
			graphregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 								///
			plotregion( color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 								///
			ysize(5) xsize(5) 	
			local nb =`.Graph.plotregion1.barlabels.arrnels'
			forval i = 1/`nb' {
				 di "`.Graph.plotregion1.barlabels[`i'].text[1]'"
				 .Graph.plotregion1.barlabels[`i'].text[1]="`.Graph.plotregion1.barlabels[`i'].text[1]'%"
			}
			.Graph.drawgraph
			graph export "$figures/repetition_by_grade.pdf", as(pdf) replace		
	}		

		
	* --------------------------------------------------------------------------------------------------------------------------------------------------------- *
	**
	**
	*Repetition prior joining the program -> we can see that repetition in t-1 helps to determine who is going to receive the treatment
	* --------------------------------------------------------------------------------------------------------------------------------------------------------- *
	{
		use "$dtfinal/SE LIGA & Acelera_Recife.dta" if distorcao  >= 1 & !missing(distorcao) & grade > 2 & grade < 6 & (status_anterior == 1 | status_anterior == 2), clear
		collapse (mean)reprovou_anterior, by(type_program grade)
		sort 	grade type_program
		replace reprovou_anterior = reprovou_anterior*100
		format  reprovou_anterior %5.2fc
		reshape wide reprovou_anterior, i(grade) j(type_program)
		
			graph bar (asis) reprovou_anterior1 reprovou_anterior2 reprovou_anterior3, bargap(-30) bar(1,  fcolor(gs12) fintensity(inten50)) 	 bar(2,  fcolor(dkorange*0.5) ) bar(3, lwidth(0.2) fcolor(navy*0.6) )			///
			over(grade, sort() label(labsize(medium)))																						///
			blabel(bar, position(outside) orientation(horizontal) size(medium) color(black) format (%4.0fc))   								///
			title("", pos(12) size(medsmall) color(black)) subtitle(, pos(12) size(medsmall) color(black)) 									///
			ytitle(, size(medsmall)) yscale(r(10 100) off) ylabel(none)  																	///
			legend(order(1 "Regular" 2 "Se Liga" 3 "Acelera" ) region(lwidth(white) color(white) lcolor(white) fcolor(white)) cols(3) size(large) position(12))      		            		///
			note("Source: EMPREL." , color(black) fcolor(background) pos(7) size(small)) 													///
			graphregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 								///
			plotregion( color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 								///
			ysize(5) xsize(6) 	
			local nb =`.Graph.plotregion1.barlabels.arrnels'
			forval i = 1/`nb' {
				 di "`.Graph.plotregion1.barlabels[`i'].text[1]'"
				 .Graph.plotregion1.barlabels[`i'].text[1]="`.Graph.plotregion1.barlabels[`i'].text[1]'%"
			}
			.Graph.drawgraph
			graph export "$figures/repetition by program.pdf", as(pdf) replace	
	}

		
	* --------------------------------------------------------------------------------------------------------------------------------------------------------- *
	**
	**
	*Status in the end of the program
	* --------------------------------------------------------------------------------------------------------------------------------------------------------- *
	{	
		use "$dtfinal/SE LIGA & Acelera_Recife.dta" if distorcao > 1 & !missing(distorcao) , clear
		collapse (sum)approved repeated dropped, by(type_program)
			graph pie approved repeated dropped, by(type_program,   note("") legend(off) graphregion(color(white)) cols(3)) pie(1, explode  color(navy*0.6)) pie(2, explode color(red*0.9) )  pie(3, explode color(gs14)) ///
			legend(off) 	 																												///
			plabel(_all percent,   						 gap(-10) format(%2.0fc) size(medsmall)) 											///
			plabel(1 "Approved",   						 gap(2)   format(%2.0fc) size(medsmall))  											///
			plabel(2 "Repeated",    					 gap(1)   format(%2.0fc) size(medsmall)) 											///
			plabel(3 "Dropped",    						 gap(6)   format(%2.0fc) size(medsmall)) 											///
			graphregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white))	 					 		///
			plotregion(color(white)  fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 						 		///
			note("Source: EMPREL.", span color(black) fcolor(background) pos(7) size(small))												///
			ysize(6) xsize(10) 	
			*graph export "$figures/status by program.pdf", as(pdf) replace	
	}	
		
		
		
	* --------------------------------------------------------------------------------------------------------------------------------------------------------- *
	**
	**
	*Size of the schools offering the program & insfrastructure
	* --------------------------------------------------------------------------------------------------------------------------------------------------------- *
	{	
	*(1)
	* --------------------------------------------------------------------------------------------------------------------------------------------------------- *
		use 	"$dtfinal/SE LIGA & Acelera_Recife.dta" if year > 2010, clear
		gen 	id = 1 if grade < 6
		collapse (sum)id el1_nesse_ano (mean)tem_programa_nesse_ano, by(year codschool)
		tempfile schools
		save    `schools'
			
		collapse (mean)id  el1_nesse_ano, 							  by(year tem_programa_nesse_ano) 
		format id %4.0fc
			twoway ///
				(line  id year if tem_programa_nesse_ano == 1, 		msymbol(T) msize(small) lwidth(0.1)  color(cranberry) 		 lp(solid) 	   connect(direct) recast(connected) mlab(id) mlabpos(6)  mlabcolor(black)) 	///
				(line  id year if tem_programa_nesse_ano == 0, 		msymbol(d) msize(small) lwidth(0.1)  color(emidblue%70)	     lp(shortdash) connect(direct) recast(connected) mlab(id) mlabpos(12) mlabcolor(black) 		///
				ysca(range() alt)  xlabel(2011(1)2018, labsize(small) gmax angle(horizontal)) 														///
				ytitle("Number of students", size(medsmall)) xtitle("", size(medsmall))																///
				ysize(5) xsize(5) 																													///
				legend(order(1 "Se Liga/Acelera" 2 "Only Regular") region(lwidth(none) lcolor(none) fcolor(none)) cols(3) size(large) position(6)) 	///
				graphregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 									///
				plotregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 									///
				note("Source: EMPREL.", color(black) fcolor(background) pos(7) size(small))) 
				graph export "$figures/size of the schools.pdf", as(pdf) replace	
				
	*(2)		
	* --------------------------------------------------------------------------------------------------------------------------------------------------------- *
		use "${censoescolar}/School Infrastructure at school level.dta" if year == 2016, clear
		merge 1:1 year codschool using `schools', keep(3) nogen
		collapse (mean) ComputerLab ScienceLab SportCourt Library InternetAccess, by (tem_programa_nesse_ano)
		rename (ComputerLab ScienceLab SportCourt Library InternetAccess) (var_1 var_2 var_3 var_4 var_5)
		reshape long var_, i(tem_programa_nesse_ano) j(infra)
		reshape wide var_, i(infra) j(tem_programa_nesse_ano)
			graph bar (asis) var_1 var_0  , graphregion(color(white)) bar(1, lwidth(0.2) lcolor(navy) color(emidblue)) bar(2, lwidth(0.2) lcolor(black) color(gs12))  bar(3, color(emidblue))   				///
			over(infra, sort(infra) relabel(1  `" "Computer" "Lab" "'   2 `" "Science" "Lab" "'   3 `" "Sport" "Court" "'  4 `" "Library" "'  5 `" "Internet" "Access" "') label(labsize(small))) 				///
			graphregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 																									///
			plotregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 																									///
			blabel(bar, position(outside) orientation(horizontal) size(vsmall)  color(black) format (%12.1fc))   																								///
			ylabel(, nogrid labsize(small) angle(horizontal)) 																																					///
			yscale(alt) 																																														///
			ysize(5) xsize(7) 																																													///
			ytitle("%", size(medsmall) color(black))  																																							///
			legend(order(1 "Implemented Program" 2 "Other schools") region(lwidth(none) color(white) fcolor(none)) cols(4) size(large) position(6))																///
			note("Source: School Census INEP 2009.", span color(black) fcolor(background) pos(7) size(vsmall))
			graph export "$figures/school_infra.pdf", as(pdf) replace	
			
				
	*(3)		
	* --------------------------------------------------------------------------------------------------------------------------------------------------------- *
		use "$dtinter/Proficiência.dta", clear
		merge m:1 codschool year using `schools', keep(3) nogen
		keep if year == 2010
		ttest prof_LP_stand, by(tem_programa_nesse_ano)

		collapse (mean)prof_MT_stand prof_LP_stand, by(grade year tem_programa_nesse_ano)
		foreach var of varlist *stand* {
			replace `var' = `var'*10
		}

			reshape long prof_, i(grade tem_programa_nesse_ano) j(sub)	string
			reshape wide prof_, i(grade sub) 		 j(tem_programa_nesse_ano)
			replace sub = "Portuguese" 	if sub == "port"
			replace sub = "Math" 		if sub == "mat"
		
			graph bar (asis) prof_0 prof_1, bargap(-30) bar(2,  lcolor(cranberry) fcolor(red) fintensity(inten70)) bar(1,  lcolor(navy) fcolor(ebblue) fintensity(inten90))			///
			over(sub, sort() label(labsize(medium)))																						///
			over(grade, sort() label(labsize(medium)))																						///
			blabel(bar, position(outside) orientation(horizontal) size(medium) color(black) format (%4.0fc))   								///
			title("", pos(12) size(medsmall) color(black)) subtitle(, pos(12) size(medsmall) color(black)) 									///
			ytitle(, size(medsmall)) yscale(r(0 10) off) ylabel(none)  																		///
			legend(order(1 "Tem Acelera" 2 "Sem Acelera")  region(lwidth(white) color(white) lcolor(white) fcolor(white)) cols(1) size(large) position(12))      		            		///
			note("Source: SAEPE." , color(black) fcolor(background) pos(7) size(small)) 													///
			graphregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 								///
			plotregion( color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 								///
			ysize(5) xsize(6) 		
	}	
		
		
		
	* --------------------------------------------------------------------------------------------------------------------------------------------------------- *
	**
	**
	*Did the students change school to participate of the program?, the vast majority of them did not
	* --------------------------------------------------------------------------------------------------------------------------------------------------------- *
	{
		use 	"$dtfinal/SE LIGA & Acelera_Recife.dta" if year > 2009 & type_program != ., clear
		bys 	cd_mat: egen A 					= min(year) if type_program == 3
		bys 	cd_mat: egen min_first_acelera  = max(A) 
		sort 	cd_mat year
		gen 	migrou_participar = 1 if type_program[_n] == 3 & cd_mat[_n] == cd_mat[_n-1] & type_program[_n-1] == 1 & codschool[_n] != codschool[_n-1] & year == min_first_acelera
		gen 	nao_migrou 		  = 1 if type_program[_n] == 3 & cd_mat[_n] == cd_mat[_n-1] & type_program[_n-1] == 1 & codschool[_n] == codschool[_n-1] & year == min_first_acelera
		keep 	if year ==   min_first_acelera
		collapse (sum) *migrou* t_acelera, by (year)
		gen p = nao_migrou/(nao_migrou+ migrou_participar)
	}	



	* --------------------------------------------------------------------------------------------------------------------------------------------------------- *
	**
	**
	*Flow and Age distortion if the schools offering the program
	* --------------------------------------------------------------------------------------------------------------------------------------------------------- *
	{
		use  "$dtfinal/SE LIGA & Acelera_Recife.dta", clear
		duplicates drop codschool year tem_programa_nesse_ano, force
		tempfile 	 schools
		save 		`schools'
		
		use codschool year approval* repetition* dropout* using "$rendimento/Flow Indicators at school level.dta", clear
		drop if year == "Fonte: Censo da Educação Básica 2017/INEP."
		destring year, replace
		merge 1:1 codschool year using `schools', keep(3) nogen
		keep if year == 2018
		
		ttest approvalEF1, 	 by(tem_programa_nesse_ano)
		ttest repetitionEF1, by(tem_programa_nesse_ano)
		ttest dropoutEF1,	 by(tem_programa_nesse_ano)
		
		use codschool year agedistortion* using "$distorcao/Age distortion at school level.dta", clear
		duplicates drop codschool year, force
		merge 1:1 codschool year using `schools', keep(3) nogen
		keep if year == 2018
		
		ttest agedistortionEF1, by(tem_programa_nesse_ano)
	}	



		
	* --------------------------------------------------------------------------------------------------------------------------------------------------------- *
	**
	**
	*Expected number of students that migrate to the state network after 5th grade
	* --------------------------------------------------------------------------------------------------------------------------------------------------------- *
	{
		use "$dtfinal/SE LIGA & Acelera_Recife.dta" if grade >= 5, clear
		sort cd_mat year
		gen continuou_rede = grade[_n] == 5 & cd_mat[_n] == cd_mat[_n+1] & year[_n] == year[_n+1] - 1
		gen deixou_rede    = grade[_n] == 5 & cd_mat[_n] != cd_mat[_n+1] 
		collapse (sum)continuou* deixou*,  	
		gen p_deixou = deixou_rede/(deixou_rede + continuou_rede)			//70% deixaram a rede
	}	
		
		
		
	* --------------------------------------------------------------------------------------------------------------------------------------------------------- *
	**
	**
	*Age range before and after program implementation
	* --------------------------------------------------------------------------------------------------------------------------------------------------------- *
	{	
		
		use "$dtfinal/SE LIGA & Acelera_Recife.dta" if type_program == 1 & tem_programa_nesse_ano == 1 & year == 2018, clear
		sort cd_turma year 
		br  	cd_turma cd_mat year grade idade distorcao dif_idade* n_alunosvaomigrar_acelera n_alunos_migraram_acelera if n_alunos_migraram_acelera > 0
		
		gen dif = dif_idade_turma - dif_idade_turma_ano_anterior  if !missing( dif_idade_turma) & !missing(dif_idade_turma_ano_anterior) & n_alunos_migraram_acelera >  0 
		su dif, detail

		
		twoway ///
				(scatter dif_idade_turma_ano_anterior dif_idade_turma  if n_alunos_migraram_acelera >  0 & dif_idade_turma != 0,  msize(vsmall) mcolor(dkorange*0.8))  	///
				(line    dif_idade_turma dif_idade_turma if dif_idade_turma > 0.5, 		msymbol(d) msize(small) lwidth(0.1)  color(emidblue%70)	     lp(shortdash) connect(direct) recast(connected)	///
				ysca(range() alt line)   ylabel(, labsize(medsmall) format(%4.0fc)) xlabel(, labsize(medsmall) gmax angle(horizontal) format(%4.0fc)) 													///
				ytitle("Dif between the oldest and the youngest of the class in t-1", size(medsmall)) xtitle("Dif between the oldest and the youngest of the class in t", size(medsmall))															///
				ysize(5) xsize(7) 																												///
				legend(order(1 "Age oldest minus age youngest" 2 "45 degree line") pos(12) cols(2) region(lwidth(white) lcolor(white) color(white) fcolor(white) )) 	///
				graphregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 								///
				plotregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 								///
				note("Source: EMPREL.", color(black) fcolor(background) pos(7) size(small))) 
				graph export "$figures/Age range.pdf", as(pdf) replace	
	}		
			

		
	* --------------------------------------------------------------------------------------------------------------------------------------------------------- *
	**
	**
	*% of students that we were able to find in SAEPE dataset 	
	* --------------------------------------------------------------------------------------------------------------------------------------------------------- *
	{
		use "$dtfinal/SE LIGA & Acelera_Recife.dta" if year > 2009 & ((grade == 5 | grade == 9) | (grade == 3 & year < 2016) | (grade == 2 & year > 2015)), clear
		
		gen 	id 		= 1 if  grade == 3 & year < 2016			//students who must have taken the test
		replace id 		= 1 if  grade == 2 & year > 2015
		replace id		= 1 if  grade == 5 | grade == 9

		
		gen 	id_profi = 1 if  grade == 3 & year < 2016 & !missing(prof_LP)
		replace id_profi = 1 if  grade == 2 & year > 2015 & !missing(prof_LP)
		replace id_profi = 1 if (grade == 5 | grade == 9) & !missing(prof_LP)

		collapse (sum)id id_profi, by  (grade)
		gen p = id_profi/(id)
	}	
		

			
	* --------------------------------------------------------------------------------------------------------------------------------------------------------- *
	**
	**
	*Share of students with age-grade distortion included in the intervention
	* --------------------------------------------------------------------------------------------------------------------------------------------------------- *
	{
		use 	"$dtfinal/SE LIGA & Acelera_Recife.dta" if year > 2009, clear
		gen  id = 1 if grade < 6
		collapse (sum)el1_nesse_ano entrou_nesse_ano_acelera id, by(year)

		replace   entrou_nesse_ano_acelera =  (entrou_nesse_ano_acelera/el1_nesse_ano)*100
		label var entrou_nesse_ano_acelera 	 "% included in Se Liga or Acelera"
		format    entrou_nesse_ano_acelera  %4.1fc
		
		label var el1_nesse_ano "Students with age distortion > 1"
		
		twoway ///
		(bar el1_nesse_ano year, barw(.5)  lcolor(navy) lwidth(0.2) fcolor(gs14) fintensity(inten60) yaxis(2))		 												 ///
		|| (scatter  entrou_nesse_ano_acelera year , symbol(O) color(dkorange*0.8) msize(medium) ml(entrou_nesse_ano_acelera) mlabcolor(black) mlabposition(12) mlabsize(3) yaxis(1) 	 ///
		ysca(axis(1) r(0 40) line) 	ylab(0(10)40,  angle(horizontal) labsize(small) format(%4.0f) axis(1)) 					 			///
		ysca(axis(2) r(10000 15000) line)  ylab(10000(1000)14000,     angle(horizontal) labsize(small) format(%4.0f) axis(2))			///
		xsca( r(2010 2018)   )     xlab(2010(1)2018,     labsize(small) format(%4.0fc)) 					///
		legend(cols(2) size(medsmall) region(lwidth(none) color(none)) pos(6))  			 				/// 		
		title("", pos(12) size(medsmall) color(black)) 														///     
		ytitle("% included in Se Liga or Acelera", axis(1) size(small) color(black))						/// 
		ytitle("Number of elegible students", axis(2) size(small) color(black)) 							///
		xtitle("", size(small))  																			///
		graphregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white))	///
		plotregion( color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 	///
		ysize(5) xsize(7)							 														///
		note("", span color(black) fcolor(background) pos(7) size(small)))
		*graph export "$figures/students_age_distortion.pdf", as(pdf) replace		
	}
		
		
		
	* --------------------------------------------------------------------------------------------------------------------------------------------------------- *
	**
	**
	*Proficiency
	* --------------------------------------------------------------------------------------------------------------------------------------------------------- *
	{
		*(1)	
		* ----------------------------------------------------------------------------------------------------------------------------------------------------- *
		use "$dtinter/Proficiência.dta" if grade < 12 , clear
		collapse (mean)prof* insuf*, by (grade year)
		format prof* insuf* %4.0fc
		
		foreach grade in 5 9 {
			if `grade' == 5 {
				local low  = 140 
				local high = 220
			}
			else {
				local low  = 180
				local high = 260
			}
			twoway ///
			(line prof_MT  year if grade == `grade', 		msymbol(d) msize(small) lwidth(0.1)  color(olive_teal*1.2)	 lp(shortdash) connect(direct) recast(connected)  mlab(prof_MT) mlabpos(12) mlabcolor(black))  ///
			(line prof_LP  year if grade == `grade', 		msymbol(t) msize(small) lwidth(0.1)  color(brown*0.8)	 	 lp(shortdash) connect(direct) recast(connected)  mlab(prof_LP) mlabpos(6)  mlabcolor(black) 	///
			ylabel(`low'(20)`high', labsize(small) gmax angle(horizontal) format(%12.0fc)) ysca(off) 								///
			xlabel(2010(1)2018, labsize(small) gmax angle(horizontal) ) 															///
			ytitle("Test score", size(medsmall)) 																					///
			xtitle("", size(medsmall))																								///
			title("`grade'{sup:th} grade", pos(12) size(huge) color(black)) 														///
			subtitle("", pos(12) size(medsmall))	 																				///
			ysize(5) xsize(5) 																										///
			legend(order(1 "Math" 2 "Portuguese") region(lwidth(none) lcolor(none) fcolor(none)) cols(3) size(large) position(6)) 	///
			graphregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white))		 				///
			plotregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white))  						///
			note("Source: SAEPE.", color(black) fcolor(background) pos(7) size(small)) saving(`grade'.gph, replace) ) 
		} 
		
			graph combine 5.gph 9.gph, ycommon ysize(5) xsize(7)
			erase 5.gph
			erase 9.gph		
			*graph export "$figures/proficiency.pdf", as(pdf) replace

		*(2)
		* ----------------------------------------------------------------------------------------------------------------------------------------------------- *
			foreach var of varlist insuf* {
				replace `var' = `var'*100
			}
			
			foreach grade in 3 5 {
				preserve
				if `grade' == 3 keep if year > 2010 & year < 2016 //third  grade has performance in Math and Portuguese from 2011 and 2015
				if `grade' == 2 keep if year > 2015 			  //second grade has performance starting in 2016
				
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
					*graph export "$figures/proficiency_insuf_`grade'.pdf", as(pdf) replace	
				restore
			}
	}		



		

		

		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
			

			
			
			
/*

		
		
		
		
		
		
		

		

*Statistics of the municipal network in Recife
* ------------------------------------------------------------------------------------------------------------------------------------------------------------- *
	use "$dtfinal/SE LIGA & Acelera_Recife.dta", clear
	codebook cd_mat 			if year == 2018 & grade < 6
	codebook cd_mat 			if year == 2010 & grade < 6
	codebook codschool 			if year == 2018 & grade < 6
	codebook codschool 			if year == 2010 & grade < 6
	codebook codschool 			if year == 2018 & grade < 6 & type_program >  1
	codebook codschool 			if year == 2010 & grade < 6 & type_program >  1
	codebook cd_mat     		if year == 2018 & grade < 6 & type_program == 2
	codebook cd_mat     		if year == 2018 & grade < 6 & type_program == 3
	codebook cd_mat     		if year == 2010 & grade < 6 & type_program == 2
	codebook cd_mat     		if year == 2010 & grade < 6 & type_program == 3
	su distorcao if (type_program == 2 | type_program == 3) & grade == 3, detail
	
	duplicates drop codschool year, force //number of schools offering Se liga e acelera within the years
	tab year tem_programa_nesse_ano
	



	


* ------------------------------------------------------------------------------------------------------------------------------------------------------------- *
**
**
*Proficiency range of the classes 
* ------------------------------------------------------------------------------------------------------------------------------------------------------------- *
{	
	use "$dtfinal/SE LIGA & Acelera_Recife.dta" if year < 2016 & grade > 3 & grade < 6 & tem_programa_nesse_ano == 1, clear
		
		bys cd_turma codschool year: egen a = min(prof_3ano)
		bys cd_turma codschool year: egen b = max(prof_3ano)
		
		gen id = 1
		bys cd_turma codschool year: egen t = sum(id) if prof_3ano != .
		gen dif = b - a if !missing(b) & !missing(a) & b > a 
		duplicates drop cd_turma codschool year, force
		
		gen p = t/students_class						//percentage of the students in the class with proficiency data
		br 	cd_turma a b dif students_class t 		
		keep if p > 0.4 & !missing(p)

		tw ///
			histogram dif if t_seliga  == 1, bin(30) fcolor(none) lcolor(navy*0.6) lw(0.6)  															///
		||  histogram dif if t_sla 	   == 0, bin(30) fcolor(none) lcolor(black) 																		///
		||  histogram dif if t_acelera == 1, bin(30) fcolor(none) lcolor(dkorange*0.8) lw(0.6) 	 														///
		legend(order(1 "Se Liga" 2 "Regular" 3 "Acelera") cols(3) size(medium)  region(lwidth(white) lcolor(white) color(white) fcolor(white) )) 		///
		ytitle(, size(medsmall)) ylabel(, labsize(small) format(%12.2fc)) 						 		 	 											///
		xtitle("Students per class", size(medium)) xlabel(,labsize(medium) format(%12.0fc)) 															///
		title("", pos(12) size(huge) color(black)) 														 												///
		subtitle("", pos(12) size(medsmall) color(black)) 																								///
		graphregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 	 											///
		plotregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white))	 											///
		ysize(5) xsize(7) 	
}		
		
				use insuf_mat insuf_port year grade dist_2mais distorcao using "$dtfinal/SE LIGA & Acelera_Recife.dta" if !missing(distorcao) & year == 2018 & (grade == 2 | grade == 5 | grade == 9), clear
		gen id = 1
		collapse (mean)insuf* (sum)id ,  by(dist_2mais grade) 
		replace insuf_mat  = insuf_mat*100
		replace insuf_port = insuf_port *100
		reshape long insuf_, i(grade dist_2mais) j(sub)			string
		reshape wide id insuf_, i(grade sub) 		 j(dist_2mais)
		replace sub = "Portuguese" 	if sub == "port"
		replace sub = "Math" 		if sub == "mat"
		graph bar (asis) insuf_0 insuf_1, bargap(-30) bar(2,  lcolor(cranberry) fcolor(red) fintensity(inten70)) bar(1,  lcolor(navy) fcolor(ebblue) fintensity(inten90))			///
		over(sub, sort() label(labsize(medium)))																						///
		over(grade, sort() label(labsize(medium)))																						///
		blabel(bar, position(outside) orientation(horizontal) size(medium) color(black) format (%4.0fc))   								///
		title("", pos(12) size(medsmall) color(black)) subtitle(, pos(12) size(medsmall) color(black)) 									///
		ytitle(, size(medsmall)) yscale(r(10 100) off) ylabel(none)  																	///
		legend(order(1 "Less than 2 years age distortion" 2 "2 or more years of age distortion")  region(lwidth(white) color(white) lcolor(white) fcolor(white)) cols(1) size(large) position(12))      		            		///
		note("Source: SAEPE." , color(black) fcolor(background) pos(7) size(small)) 													///
		graphregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 								///
		plotregion( color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 								///
		ysize(5) xsize(6) 	
		local nb =`.Graph.plotregion1.barlabels.arrnels'
		forval i = 1/`nb' {
			 di "`.Graph.plotregion1.barlabels[`i'].text[1]'"
			 .Graph.plotregion1.barlabels[`i'].text[1]="`.Graph.plotregion1.barlabels[`i'].text[1]'%"
		}
		.Graph.drawgraph
		graph export "$figures/insufficient performance by grade.pdf", as(pdf) replace	
		

	 use 	"$dtfinal/SE LIGA & Acelera_Recife.dta" if (year < 2016 & (grade == 3 | grade == 5 | grade == 9)) | (year > 2015 & (grade == 2 | grade == 5 | grade == 9)), clear
	 gen 	id = 1
	 gen 	id_pr= 1 if !missing(prof_MT)
	 collapse (sum)id id_pr , by(grade year)
	 gen p = (id_pr/id)*100
	 keep p year grade
	 replace grade = 3 if grade == 2
	 reshape wide p, i(year) j(grade)
		
		graph hbar (asis) p3, bargap(-30) bar(1,  fcolor(gs12) fintensity(inten50)) 	 bar(2,  fcolor(dkorange*0.5) ) bar(3, lwidth(0.2) fcolor(navy*0.6) )			///
		over(year, sort() label(labsize(medium)))																						///
		blabel(bar, position(outside) orientation(horizontal) size(medium) color(black) format (%4.0fc))   								///
		title("", pos(12) size(medsmall) color(black)) subtitle(, pos(12) size(medsmall) color(black)) 									///
		ytitle(, size(medsmall)) yscale(r(10 100) off) ylabel(none)  																	///
		legend(order(1 "Regular" 2 "Se Liga" 3 "Acelera" ) region(lwidth(white) color(white) lcolor(white) fcolor(white)) cols(3) size(large) position(12))      		///
		note("Source: EMPREL." , color(black) fcolor(background) pos(7) size(small)) 													///
		graphregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 								///
		plotregion( color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 								///
		ysize(5) xsize(6) 	
		
	use "$dtfinal/SE LIGA & Acelera_Recife.dta" if year == 2018, clear
		foreach grade in 2 3 5 9 {
			su 		distorcao 		if grade == `grade', detail
			replace distorcao = . 	if grade == `grade' & distorcao > r(p99)
		}
			twoway ///
			(scatter prof distorcao if grade == 5, symbol(O) color(cranberry*0.8) msize(0.2)) 	 ///
			|| lfit prof distorcao, ///
				yscale(alt line ) ylabel(,format(%4.1fc)) ///
				xtitle("Years of age distortion", size(medmsmall)) ///
				legend(cols(2) size(medsmall) region(lwidth(none) color(none)) pos(6))  			 				/// 		
				graphregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white))	///
				plotregion( color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 	///
				ysize(5) xsize(7)							 														///
				note("Source: SAEPE.", span color(black) fcolor(background) pos(7) size(small))
				graph export "$figures/proficiency_distortion_5.pdf", as(pdf) replace	

		scatter prof distorcao  if grade == 5 & year == 2018, msize(vtiny) || qfit prof distorcao
	
	
	
	
	
		
	
*Proficiency prior joining the program
* ------------------------------------------------------------------------------------------------------------------------------------------------------------- *
	use "$dtfinal/SE LIGA & Acelera_Recife.dta" if year < 2016, clear
		tw ///
		||  histogram prof if type_program	 == 1		& (en_3ano_acelera == 1 | el1_3ano == 1), bin(30) fcolor(none) lcolor(black) 					///
		||  histogram prof if t_acelera == 1  		    & (en_3ano_acelera == 1 | el1_3ano == 1), bin(30) lw(0.6) fcolor(none) lcolor(dkorange*0.8)  	///
		legend(order(1 "Regular" 2 "Acelera") cols(3) size(medium) region(lwidth(white) lcolor(white) color(white) fcolor(white))) 	///
		ytitle(, size(medsmall)) ylabel(, labsize(small) format(%12.1fc)) 						 		 	 ///
		xtitle("Proficiency (0-10)", size(medium)) xlabel(,labsize(medium) format(%12.0fc)) 				 ///
		title("Third-Grade", pos(12) size(huge) color(black)) 												 ///
		subtitle("", pos(12) size(medsmall) color(black)) 													 ///
		graphregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 	 ///
		plotregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white))	 ///
		ysize(5) xsize(7) 																					 ///
		note("Source: SAEPE", color(black) fcolor(background) pos(7) size(small)) 
		graph export "$figures/prof_antes_3.pdf", as(pdf) replace	
	
	
	
	
	use "$dtfinal/SE LIGA & Acelera_Recife.dta" if year < 2016 & inlist(tipo_escola, 2,3,4), clear
	foreach grade in 4 5 {
		if `grade' == 4 local title = "Forfh-grade"
		if `grade' == 5 local title = "Fifth-grade"

		tw ///
			histogram prof_3ano if t_seliga  == 1 		& (en_`grade'ano == 1 | el_`grade'ano  == 1), bin(30) fcolor(none) lcolor(navy*0.6)  			///
		||  histogram prof_3ano if type	 == 0 		& (en_`grade'ano == 1 | el_`grade'ano  == 1), bin(30) fcolor(none) lcolor(black) 				///
		||  histogram prof_3ano if t_acelera == 1  		& (en_`grade'ano == 1 | el_`grade'ano  == 1), bin(30) fcolor(none) lcolor(dkorange*0.8)  		///
		legend(order(1 "Se Liga" 2 "Regular" 3 "Acelera") cols(3) size(medium) region(lwidth(white) lcolor(white) color(white) fcolor(white) )) 		///
		ytitle(, size(medsmall)) ylabel(, labsize(small) format(%12.1fc)) 						 		 	 ///
		xtitle("Proficiency (0-10)", size(medium)) xlabel(,labsize(medium) format(%12.0fc)) 				 ///
		title("`title'", pos(12) size(huge) color(black)) 													 ///
		subtitle("", pos(12) size(medsmall) color(black)) 													 ///
		graphregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 	 ///
		plotregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white))	 ///
		ysize(5) xsize(7) 																					 ///
		note("Source: SAEPE", color(black) fcolor(background) pos(7) size(small)) 
		graph export "$figures/prof_antes_`grade'.pdf", as(pdf) replace	
	}
	
	
	
	
	
	
	
	
	
	
	
	

	*Distortion and proficiency when joined the program
	* ----------------------------------------------------------------------------------------------------- *
		use "$dtfinal/SE LIGA & Acelera_Recife.dta" if distorcao  >= 1 & !missing(distorcao) & year == 2018 & grade > 2 & grade < 6, clear
		
		tab grade type_program
		tab grade type_program if !missing(prof_MT_antes_programa)

		foreach grade in 3 4 5 {
			foreach var in prof_MT_antes_programa prof_LP_antes_programa distorcao {
				su 		`var' 		if grade == `grade', detail
				replace `var' = .   if grade == `grade' & (`var' <= r(p1) | `var' >= r(p99))
			}
		}
		
		foreach grade in 3 4 5 {
			tabform distorcao prof_MT_antes_programa prof_LP_antes_programa if grade ==`grade' using "$tables/Grade`grade'.xls" , by(type_program) sd sdbracket nototal bdec(2)  vertical 
		}
		
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	

		**
	*Number of participant students per school
	**--------------------------------------------------------------------------------------------------------------------------------------------------------- *
	use "$dtfinal/SE LIGA & Acelera_Recife.dta" if grade>= 3 & grade <= 5 & year >= 2010, clear
	
	egen classe = tag(codigo_turma)
	gen  mat   = 1
	
	bys codschool year: egen tem_seliga  = max(t_seliga)
	bys codschool year: egen tem_acelera = max(t_acelera)
	
	clonevar med_dist1 =  dist_1mais
	clonevar med_dist2  = dist_2mais
	
	
	
	
	
	collapse (sum) mat turma dist_1mais dist_2mais (mean)reprovou_anterior med_dist1 med_dist2 (max)tem_seliga tem_acelera, by(codschool grade year)
	
	drop dist_1mais dist_2mais
	
	reshape wide mat turma reprovou_anterior med_dist1 med_dist2, i(codschool year tem_seliga tem_acelera) j(grade) 
	
	reg tem_seliga mat3 turma3 reprovou_anterior3 med_dist13 med_dist23 i.year
	
	predict xb
	
	
	psmatch2 tem_seliga mat3 turma3 reprovou_anterior3 med_dist13 med_dist23, n(3) common  ties 
	
	tw kdensity _pscore if tem_seliga == 1 [aw = _weight],  lw(thick) lp(dash) color(emidblue) 	///
											///
    || kdensity _pscore if tem_seliga == 0 [aw = _weight],  lw(thick) lp(dash) color(gs12) 	
										
										
							/*
	Number of schools and students in Recife
	*/

		
		use 	"$dtfinal/SE LIGA & Acelera_Recife.dta" if grade > 2 & grade < 6 & year > 2009 & year < 2018, clear
		
		
		
		
		**
		*Numero de escolas oferencendo educação regular, se liga e acelera
		egen escola_regular = tag(codschool year) 	if type_program == 1
		egen escola_sla 	= tag(codschool year)	if type_program == 2 | type_program == 3



	/*
		graph pie t_seliga t_acelera if grade == `grade' & year == 2018, pie(1, explode  color(navy*0.6)) pie(2, explode color(dkorange*0.8))  pie(3, explode color(gs14)) ///
		plabel(_all percent,   						 gap(-15) format(%2.0fc) size(large)) 												///
		plabel(1 "Se Liga",   						 gap(2)   format(%2.0fc) size(large)) 												///
		plabel(2 "Acelera",    						 gap(2)   format(%2.0fc) size(large)) 												///
		title("`title'" , pos(12) size(huge) color(black)) 																				///
		legend(off) 																													///
		graphregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white))	 					 		///
		plotregion(color(white)  fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 						 		///
		note("Source: EMPREL..", span color(black) fcolor(background) pos(7) size(small))											///
		ysize(5) xsize(5) 	
		graph export "$figures/participants_`grade'.pdf", as(pdf) replace	
	*/
		


						
	
	
	
