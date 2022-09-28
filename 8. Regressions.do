
	
	**
	**Covariadas ao nivel da escola
	global schoolinfra EnergyAccess SewerAccess WaterAccess Computer Library ComputerLab ScienceLab SportCourt InternetAccess SchoolEmployees BroadBandInternet
	
		
	**PROGRAMA PARA RODAR PARA GARANTIR QUE ALUNOS TRATADOS TENHAM UMA OBSERVAÇÃO ANTES E DEPOIS DA PARTICIPAÇÃO
	* _____________________________________________________________________________________________________________________________________________________________ *
	{
		cap program drop baseline
		program define   baseline
	
			*Identificacao dos alunos sem baseline, quem nunca participou, sempre tem baseline
			* ----------------------------------------------------------------------------------------------------------------------------------------------------- *
			bys  cd_mat: egen first_acelera     = min(year) if type_program == 3								
			bys  cd_mat: egen min_first_acelera = min(first_acelera)
			
			
			drop if primeiro_ano_painel == min_first_acelera //alunos participantes que nao tem baseline porque a pimeira 
			bys 	cd_mat: gen total = _N 
			drop 	if		    total == 1
			
		end 
	}
	
	
	**PROGRAMA PARA CRIAR AS VARIAVEIS DE LEADS AND LAGS
	* _____________________________________________________________________________________________________________________________________________________________ *
	{
		cap program drop leadlag
		program define   leadlag
		
			sort cd_mat year
					
			**
			forvalues i = 1(1)2 {
				gen 	lead_`i'= (year - min_first_acelera == - `i')    
				gen 	lag_`i' = (year - min_first_acelera ==   `i') 
			}
			gen 	 	lag_0   = year == min_first_acelera
			
			gen  		lead_3   = year - min_first_acelera < - 2 & acelera2014 == 1 
			gen  		lag_3    = year - min_first_acelera >   2 & acelera2014 == 1 
			
			gen 	 	lag_0seliga    = year == min_first_acelera  & seliga2014 == 1 
			
			///
			*drop if (lead_1 + lead_2 + lag_0 + lag_1 + lag_2 == 0) & acelera2014 == 1
			
		end
	}
	
	
	**PROGRAMA PARA CALCULAR O NUMERO DE TRATAMENTOS E DE CONTROLE
	* _____________________________________________________________________________________________________________________________________________________________ *
	{
	cap program drop treated_control
	program define   treated_control
	syntax, test(string) outcome(varlist)
	
		local ATT = el(r(table),1,1)
	
		unique cd_mat    if e(sample) == 1 & acelera2014 == 1						
		scalar unique_treat  = r(unique)
				
		unique cd_mat    if e(sample) == 1 & acelera2014 == 0						//number of schools in the control group
		scalar unique_control = r(unique)
				
		unique codschool if e(sample) == 1 											//number of schools in the control group
		scalar unique_school = r(unique)
		
		su `outcome' [aw = _weight] if acelera2014 == 1 & year < min_first_acelera & e(sample) == 1
		scalar outcome_treat = r(mean)
		scalar sd_treat		 = r(sd)
		
		su `outcome' [aw = _weight] if acelera2014 == 0	 						   & e(sample) == 1
		scalar outcome_control = r(mean)
		
		scalar ATT_sd = `ATT'/sd_treat	
		
		estadd scalar unique_control   = unique_control  : test`test'
		estadd scalar unique_treat	   = unique_treat    : test`test'
		estadd scalar unique_school	   = unique_school   : test`test'
		estadd scalar outcome_treat    = outcome_treat   : test`test'		
		estadd scalar outcome_control  = outcome_control : test`test'
		estadd scalar sd_treat	  	   = sd_treat	     : test`test'
		estadd scalar ATT_sd	  	   = ATT_sd	         : test`test'
	end
	}
	
	
	**PROGRAMA PARA CRIAR DIFERENTES GRUPOS DE COMPARACAO
	* _____________________________________________________________________________________________________________________________________________________________ *
	{	
		cap program drop sample
		program define   sample
		syntax, 				grade(integer) criteria_eleg(integer) spec(string) ultimo_ano(integer)
		
			xtset cd_mat year	
		
			*criteria_eleg em t = 1 se distorcao > 1
			*criteria_eleg em t = 2 se distorcao > 1 & reprovou em t - 1
			
			*
			* -> Em todas as especificações, restringimos a análise a alunos elegíveis que não entraram na intervenção e alunos que entraram
				
			**
			**(A) Incluindo todas as escolas na análise (inclusive aquelas que nao empregaram a intervenção)
			* ----------------------------------------------------------------------------------------------------------------------------------------------------- *
			if "`spec'" == "A" {
				forvalues year = 2010(1)`ultimo_ano' {
					preserve
					 if `grade' != 0	keep 		if ((el`criteria_eleg'_`grade'ano == 1 & t_acelera == 1 & ja_participou_acelera == 0) | (el`criteria_eleg'_`grade'ano == 1 & type_program == 1 & ja_participou_acelera == 0)) & year == `year' //Por serie
					 if `grade' == 0	keep 		if ((el`criteria_eleg'_nesse_ano  == 1 & t_acelera == 1 & ja_participou_acelera == 0) | (el`criteria_eleg'_nesse_ano  == 1 & type_program == 1 & ja_participou_acelera == 0)) & year == `year' //pooled
						//grupo de comparacao sao todos aqueles que eram elegiveis a participar do programa naquela serie avaliada, mas que nao entraram (podem ou nao ter entrado depois)
						tempfile 	`year'
						save       ``year''
					restore
				}
			}
				
				
			**
			**(B) Incluindo apenas as escolas que ofereceram a intervenção acelera naquele ano
			* ----------------------------------------------------------------------------------------------------------------------------------------------------- *
			if "`spec'" == "B" {
				forvalues year = 2010(1)`ultimo_ano' {
					preserve
					 if `grade' != 0	keep 		if ((el`criteria_eleg'_`grade'ano == 1 & t_acelera == 1 & ja_participou_acelera == 0) | (el`criteria_eleg'_`grade'ano == 1 & type_program == 1 & ja_participou_acelera == 0)) & year == `year' & tem_acelera_nesse_ano == 1 //Por serie
					 if `grade' == 0	keep 		if ((el`criteria_eleg'_nesse_ano  == 1 & t_acelera == 1 & ja_participou_acelera == 0) | (el`criteria_eleg'_nesse_ano  == 1 & type_program == 1 & ja_participou_acelera == 0)) & year == `year' & tem_acelera_nesse_ano == 1  //pooled
						//grupo de comparacao sao todos aqueles que eram elegiveis a participar do programa naquela serie avaliada, mas que nao entraram (podem ou nao ter entrado depois)
						tempfile 	`year'
						save       ``year''
					restore
				}
			}
				
				
			**
			*Append das matrículas que precisam estar na regressão	
			* ------------------------------------------------------------------------------------------------------------------------------------------------------ *
			if "`spec'" == "A" | "`spec'" == "B" {

			preserve
				clear
				forvalues year = 2010(1)`ultimo_ano' {
					append using ``year''
				}
				duplicates drop cd_mat, force
				keep 		cd_mat
				tempfile   sample
				save      `sample'
			restore
			
			} 
			
			
			**
			**(C) e (D) Matching
			* ------------------------------------------------------------------------------------------------------------------------------------------------------ *
			if "`spec'" == "C" | "`spec'" == "D" {		//matching
				
				**
				**Elegiveis
				forvalues year = 2010(1)`ultimo_ano' {
					preserve
					if "`spec'" == "D"  keep if tem_acelera_nesse_ano == 1  & year == `year' //apenas as escolas que oferecem o programa
					if `grade' != 0	keep 		if ((el`criteria_eleg'_`grade'ano == 1 & t_acelera == 1 & ja_participou_acelera == 0) | (el`criteria_eleg'_`grade'ano == 1 & type_program == 1 & ja_participou_acelera == 0)) //Por serie
					if `grade' == 0	keep 		if ((el`criteria_eleg'_nesse_ano  == 1 & t_acelera == 1 & ja_participou_acelera == 0) | (el`criteria_eleg'_nesse_ano  == 1 & type_program == 1 & ja_participou_acelera == 0)) //pooled
					tempfile `year'
					save    ``year''
					keep 	cd_mat 
					restore
				}
				
				**
				**Appeding elegiveis				
					preserve
					clear
					forvalues year = 2010(1)`ultimo_ano' {
						append using ``year''
					}
					duplicates drop cd_mat, force
					tempfile   sample
					save      `sample'
					restore
				
				**
				**Matching	
					preserve
					merge m:1 cd_mat using `sample', keep(3) nogen
				
					psmatch2 acelera`ultimo_ano' distorcao ja_participou_seliga i.status_anterior i.codschool i.year gender dif_idade_turma , n(3) common ties
					if "`spec'" == "D" & `grade' == 0{
						if `grade' == 0 local title = "Pooled"
						if `grade' == 3 local title = "3{sup:rd} grade"
						if `grade' == 4 local title = "4{sup:th} grade"
						if `grade' == 5 local title = "5{sup:th} grade"
				
						tw kdensity _pscore if acelera2014 == 1  [aw = _weight],  lw(1.5) lp(dash) color(red) 				///
						///
						|| kdensity _pscore if acelera2014 == 1  [aw = _weight],  lw(thick) lp(dash) color(gs12) 			///
						graphregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 	///
						plotregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 	///
						ylabel(, labsize(small) angle(horizontal) format(%2.1fc)) 											///
						xlabel(, labsize(small) gmax angle(horizontal)) 													///
						ytitle("Density", size(medsmall))			 														///
						xtitle("Propensity score", size(medsmall)) 															///
						title("`title'", pos(12) size(medsmall)) 															///
						subtitle(, pos(12) size(medsmall)) 																	///
						ysize(5) xsize(7) 						///
						legend(order(1 "Treated" 2 "Comparison") pos(6) region(lstyle(none) fcolor(none)) size(medsmall))  ///
						note("", color(black) fcolor(background) pos(7) size(small) )  
						graph export "$figures/FigureB5.pdf", as(pdf) replace
					}
					
					keep 		if _support == 1						
					keep 		if _weight != .
					duplicates 	drop cd_mat, force
					keep 			cd_mat _weight
					tempfile  	 sample
					save        `sample'
					restore	
			}	

			
			**
			*Merging the required sample with the main dataset
			* --------------------------------------------------------------------------------------------------------------------------------------------------------- *
			{
				merge m:1 cd_mat using `sample', keep(3)
				
				if "`spec'" == "A" | "`spec'" == "B"  gen _weight = 1
				
				if `ultimo_ano' != 2018 baseline			//so mantendo alunos que apresentam baseline
				
				if `ultimo_ano' != 2018 leadlag				//criando as variaveis de leads and lags
				
			}
		
			/*
			**
			*Trend
			* --------------------------------------------------------------------------------------------------------------------------------------------------------- *
			{
				keep if e(sample) == 1
				
				forvalues year = 2010(1)`ultimo_ano' {
					preserve
					keep 		if (min_first_acelera == `year' | none2014 == 1)
					gen         T  =  none2014 == 0
					collapse 	(mean)approved repeated dropped, by (year T) 
					gen	 		ano_tratamento = `year'
					tempfile    `year'
					save       ``year''
					restore
				}
				
				clear
				forvalues year = 2010(1)`ultimo_ano' {
					append using ``year''
				}				
				save 		"$dtinter/trend_`criteria_eleg'_`grade'_`spec'.dta", replace
			}
			*/
			
		end
	}
	
	
	/*
	* _____________________________________________________________________________________________________________________________________________________________ *
	**
	**
	*DiD & leads and lags
	**
	* _____________________________________________________________________________________________________________________________________________________________ *

	Variável d_acelera assume valor 1 para depois do tratamento e 0 caso contrario. 
	
	Neste exercício: 
		-> Comparamos quem entrou no Acelera no (3o, 4o, ou 5o ano) com quem era elegivel mas nao entrou (por elegível, dizemos quem tinha distorção de pelo menos um ano).
		-> 
	*---------------------------------------------------------------------------------------------------------------------------------------------------------------*
	*/
	
		* __________________________________________________________________________________________________________________________________________________________ *
		**
		**
		*Table 1
		*-----------------------------------------------------------------------------------------------------------------------------------------------------------*
		**
		estimates clear
		
		**
		foreach grade in 0 { 

			foreach outcome in approved dropped dist_2mais {  //dropped 
			
				if "`outcome' " ==  "approved" local title = "Approval"
				if "`outcome' " ==  "repeated" local title = "Repetition"
				if "`outcome' " ==  "dropped"  local title = "Dropout"
				
				local i = 1
				
					foreach spec in  A B C D {
						
						use 	"$dtfinal/SE LIGA & Acelera_Recife.dta" if year < 2015, clear
						
						****--------------------------->>>
						drop if seliga2014 == 1
						****--------------------------->>>

						sample, grade(`grade') criteria_eleg(1) spec("`spec'") ultimo_ano(2014)
						
							eststo test`i', title("DiD")		:  xtreg `outcome'  d_acelera									  i.codschool i.year i.grade i.gender students_class dif_idade_turma distorcao $schoolinfra 										[aw = _weight], cluster(cd_mat) fe  // aqui chegamos ate a considerar colocar apenas entrou_1ano, mas inflamos o efeito do tratamento porque comparamos quem entrou  (mas nao necessariamente era elegivel) com apenas controles elegiveis
							treated_control, test(`i') outcome(`outcome')
							local i = `i' + 1
							
							eststo test`i', title("Leads, lags"):  xtreg `outcome'  lag_0 lead_2 lead_1 lag_1 lag_2  			  i.codschool i.year i.grade i.gender students_class dif_idade_turma distorcao $schoolinfra 	    [aw = _weight], cluster(cd_mat) fe  // aqui chegamos ate a considerar colocar apenas entrou_1ano, mas inflamos o efeito do tratamento porque comparamos quem entrou  (mas nao necessariamente era elegivel) com apenas controles elegiveis
							treated_control, test(`i') outcome(`outcome')
							local i = `i' + 1

						
					}
					
					if "`outcome'" == "approved" {
					estout * using "$tables/Table1.xls",  keep(d_acelera lag_0)  title("`title'")  label mgroups("No matching" "Matching", pattern(1 0 0 0 1 0 0 0)) cells(b(star fmt(2)) se(fmt(2))  ci(par)) starlevels(* 0.10 ** 0.05 *** 0.01) stats(N r2 space unique_treat outcome_treat sd_treat ATT_sd space unique_control outcome_control unique_school  , labels("Obs" "R2" "Treated Group" "Students" "Mean outcome" "SD" "ATT in sd" " Comparison Group" "Students" "Mean outcome"  "Num. schools") fmt(%9.0g %9.2f %9.2f)) replace
					}
					else{
					estout * using "$tables/Table1.xls",  keep(d_acelera lag_0)  title("`title'")  label mgroups("No matching" "Matching", pattern(1 0 0 0 1 0 0 0)) cells(b(star fmt(2)) se(fmt(2))  ci(par)) starlevels(* 0.10 ** 0.05 *** 0.01) stats(N r2 space unique_treat outcome_treat sd_treat ATT_sd space unique_control outcome_control unique_school  , labels("Obs" "R2" "Treated Group" "Students" "Mean outcome" "SD" "ATT in sd" "Comparison Group" "Students" "Mean outcome"  "Num. schools") fmt(%9.0g %9.2f %9.2f)) append
					}
					estimates clear		
			}	
		}
		
		
		* __________________________________________________________________________________________________________________________________________________________ *
		**
		**
		*Table 3
		*-----------------------------------------------------------------------------------------------------------------------------------------------------------*
		**
		estimates clear
		
		**
		foreach grade in 0  { 

			foreach outcome of varlist approved dropped {  //dropped 
			
				if "`outcome' " ==  "approved" local variable = "Approval"
				if "`outcome' " ==  "repeated" local variable = "Repetition"
				if "`outcome' " ==  "dropped"  local variable = "Dropout"
				
				local i = 1
				
					foreach spec in A B C D {
						if "`spec'" == "A" | "`spec'" == "C" local  title = "All schools"
						if "`spec'" == "B" | "`spec'" == "D" local  title = "Acelera schools"
						
						use 	"$dtfinal/SE LIGA & Acelera_Recife.dta" if year < 2015, clear
						
						****--------------------------->>>
						drop if seliga2014 == 1 & acelera2014 == 0 //quem fez se liga vai melhor no acelera?, estamos tirando do grupo de controle quem ja fez se liga
						****--------------------------->>>

						gen d_aceleraseliga =  d_acelera == 1 & seliga2014 == 1
						sample, grade(`grade') criteria_eleg(1) spec("`spec'") ultimo_ano(2014)
						
							eststo test`i', title("DiD")		:  xtreg `outcome'  i.codschool i.year i.grade i.gender students_class dif_idade_turma distorcao $schoolinfra d_acelera	d_aceleraseliga									   [aw = _weight], cluster(cd_mat) fe  // aqui chegamos ate a considerar colocar apenas entrou_1ano, mas inflamos o efeito do tratamento porque comparamos quem entrou  (mas nao necessariamente era elegivel) com apenas controles elegiveis
							treated_control, test(`i') outcome(`outcome')
							local i = `i' + 1
							
							eststo test`i', title("Leads, lags"):  xtreg `outcome'  i.codschool i.year i.grade i.gender students_class dif_idade_turma distorcao $schoolinfra lag_0 lead_2 lead_1 lag_1 lag_2 lag_0seliga    [aw = _weight], cluster(cd_mat) fe  // aqui chegamos ate a considerar colocar apenas entrou_1ano, mas inflamos o efeito do tratamento porque comparamos quem entrou  (mas nao necessariamente era elegivel) com apenas controles elegiveis
							treated_control, test(`i') outcome(`outcome')
							local i = `i' + 1
					}
	
					if "`outcome'" == "approved" {
					estout * using "$tables/Table3.xls",  keep(d_acelera d_aceleraseliga lag_0 lag_0seliga)  title("`variable'")  label mgroups("No matching" "Matching", pattern(1 0 0 0 1 0 0 0)) cells(b(star fmt(2)) se(fmt(2))) starlevels(* 0.10 ** 0.05 *** 0.01) stats(N r2 unique_treat unique_control unique_school, labels("Obs" "R2" "Treated" "Comparison" "Num. schools") fmt(%9.0g %9.2f %9.2f)) replace
					}
					else{
					estout * using "$tables/Table3.xls",  keep(d_acelera d_aceleraseliga lag_0 lag_0seliga)  title("`variable'") label mgroups("No matching" "Matching", pattern(1 0 0 0 1 0 0 0)) cells(b(star fmt(2)) se(fmt(2))) starlevels(* 0.10 ** 0.05 *** 0.01) stats(N r2 unique_treat unique_control unique_school, labels("Obs" "R2" "Treated" "Comparison" "Num. schools") fmt(%9.0g %9.2f %9.2f)) append
					}
					estimates clear		
			}	
		}
		* __________________________________________________________________________________________________________________________________________________________ *		
		
		
		**
		*Figure 1
		*-----------------------------------------------------------------------------------------------------------------------------------------------------------*
		{
		*		
		*Estimation by grade
		* ------------------------------------------------------------------------------------------------------------------------------------------------------*
		foreach grade in 0  {
				
			use 	"$dtfinal/SE LIGA & Acelera_Recife.dta" if year < 2015, clear	
			xtset 	cd_mat year
		
			****--------------------------->>>
			drop if seliga2014 == 1
			****--------------------------->>>
				**
				*Chart titles
				* --------------------------------------------------------------------------------------------------------------------------------------------------*
				if `grade' == 0 local title = "Pooled sample"
				if `grade' == 3 local title = "3{sup:rd} grade"
				if `grade' == 4 local title = "4{sup:th} grade"
				if `grade' == 5 local title = "5{sup:th} grade"
				
				**
				*Matching
				* --------------------------------------------------------------------------------------------------------------------------------------------------*
				{
					**
					**Elegiveis
					forvalues year = 2010(1)2014 {
						preserve
						keep if tem_acelera_nesse_ano == 1  & year == `year' 			//apenas as escolas que oferecem o programa
						if `grade' == 5 | `grade' == 4 keep if ((el1_`grade'ano == 1  & t_acelera == 1 & ja_participou_acelera == 0) | (el1_`grade'ano == 1 & type_program == 1 & ja_participou_acelera == 0)) //Por serie
						if `grade' == 3				   keep if ((el2_`grade'ano == 1  & t_acelera == 1 & ja_participou_acelera == 0) | (el2_`grade'ano == 1 & type_program == 1 & ja_participou_acelera == 0)) //Por serie
						if `grade' == 0 			   keep if (((el1_nesse_ano  == 1 & t_acelera == 1 & ja_participou_acelera == 0) | (el1_nesse_ano  == 1 & type_program == 1 & ja_participou_acelera == 0)) & inlist(grade, 1, 2, 4, 5)) |  ///
															   (((el2_nesse_ano  == 1 & t_acelera == 1 & ja_participou_acelera == 0) | (el2_nesse_ano  == 1 & type_program == 1 & ja_participou_acelera == 0)) & inlist(grade, 3))			//pooled
					
						tempfile `year'
						save    ``year''
						keep 	cd_mat 
						restore
					}
					
					**
					**Appeding elegiveis				
						preserve
						clear
						forvalues year = 2010(1)2014 {
							append using ``year''
						}
						duplicates drop cd_mat, force
						tempfile   sample
						save      `sample'
						restore
					
					**
					**Matching	
						preserve
						merge m:1 cd_mat using `sample', keep(3) nogen
					
						psmatch2 acelera2014 distorcao ja_participou_seliga i.status_anterior i.codschool i.year gender dif_idade_turma, n(3) common ties
					
							tw kdensity _pscore if acelera2014 == 1  [aw = _weight],  lw(1.5) lp(dash) color(red) 				///
							///
							|| kdensity _pscore if acelera2014 == 1  [aw = _weight],  lw(thick) lp(dash) color(gs12) 			///
							graphregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 	///
							plotregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 	///
							ylabel(, labsize(small) angle(horizontal) format(%2.1fc)) 											///
							xlabel(, labsize(small) gmax angle(horizontal)) 													///
							ytitle("", size(medsmall))			 																///
							xtitle("Propensity score", size(medsmall)) 															///
							title("", pos(12) size(medsmall)) 																	///
							subtitle(, pos(12) size(medsmall)) 																	///
							ysize(5) xsize(7) 																					///
							legend(order(1 "T" 2 "C") pos(6) region(lstyle(none) fcolor(none)) size(medsmall))  ///
							note("", color(black) fcolor(background) pos(7) size(small)) 

						keep 		if _support == 1						
						keep 		if _weight != .
						duplicates  drop cd_mat, force
						keep 			cd_mat _weight
						tempfile   	sample
						save       `sample'
						restore	
				}
				
				**
				*Merging the required sample with the main dataset
				* --------------------------------------------------------------------------------------------------------------------------------------------------*
				{
					merge m:1 cd_mat using `sample', keep(3) nogen

					baseline
					
					leadlag
				}

				**
				*Reg
				* --------------------------------------------------------------------------------------------------------------------------------------------------*
				{
				xtreg approved i.codschool i.year i.grade i.gender students_class dif_idade_turma distorcao $schoolinfra lead_1 lead_2 lag_0 lag_2 lag_1 [aw = _weight], fe vce(robust)
				}
				
				
				**
				*Results
				* --------------------------------------------------------------------------------------------------------------------------------------------------*
				matrix A = r(table)
				local col_final   = colsof(A) - 1
				local col_inicial = colsof(A) - 6
	
				clear
				svmat A
				drop in 9
				drop in 8
				drop in 7
				drop in 4
				drop in 3
				drop in 2
				keep A`col_inicial'- A`col_final'
				
				xpose, clear
	
				
				gen 	tempo =  0 in 4
				replace tempo = -3 in 1	
				replace tempo = -2 in 2
				replace tempo = -1 in 3
				replace tempo =  1 in 5
				replace tempo =  2 in 6
			
				set scheme economist
				if `grade' == 0 {
					twoway ///
					(line v1 tempo if tempo <  0, ml(v1) msymbol(O) msize(medium) color(cranberry)) 					///
					(line v1 tempo if tempo >= 0, ml(v1) msymbol(D) msize(medium) color(emidblue)) 						///
					(rcap v2 v3 tempo, lcolor(navy)																		///
					yline(0, lp(shortdash) lcolor(cranberry)) 															///
					xline(0, lp(shortdash) lcolor(cranberry)) 															///
					graphregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 	///
					plotregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 	///
					ylabel(, labsize(medsmall) format(%2.1fc)) 															///
					xlabel(-3(1)2, labsize(medsmall) gmax angle(horizontal)) 											///
					yscale(alt)																							///
					ytitle("Variation, in pp", size(medsmall))			 							///
					xtitle("") 																							///
					title("`title'", pos(12) size(medsmall)) 															///
					subtitle(, pos(12) size(medsmall)) 																	///
					text(-2 0.2 "Intervention", size(vsmall))														///
					ysize(5) xsize(7) 						///
					legend(order(1 "Before intervention" 2 "During and after intervention") pos(6) size(medsmall) region(lwidth(none) color(none))))  		
					graph export "$figures/Figure1.pdf", as(pdf) replace	

				}
				else
				{
					twoway ///
					(line v1 tempo if tempo <  0, ml(v1) msymbol(O) msize(medium) color(cranberry)) 					///
					(line v1 tempo if tempo >= 0, ml(v1) msymbol(D) msize(medium) color(emidblue)) 						///
					(rcap v2 v3 tempo, lcolor(navy)																		///
					yline(0, lp(shortdash) lcolor(cranberry)) 															///
					xline(0, lp(shortdash) lcolor(cranberry)) 															///
					graphregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 	///
					plotregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 	///
					ylabel(, labsize(medsmall) format(%2.1fc)) 															///
					xlabel(-2(1)2, labsize(medsmall) gmax angle(horizontal)) 											///
					yscale(alt)																							///
					ytitle("Variation, in pp", size(small))			 													///
					xtitle("") 																							///
					title("`title'", pos(12) size(medsmall)) 															///
					subtitle(, pos(12) size(medsmall)) 																	///
					text(-2 0.2 "Intervention", size(vsmall))															///
					ysize(5) xsize(7) 	saving("$figures/Acelera_leads&lags_`grade'grade.gph", replace)					///
					legend(off))  		
				}
				}
			}
				
			**
			*Combining charts
			* ------------------------------------------------------------------------------------------------------------------------------------------------------*
			/*
			graph combine "$figures/Acelera_leads&lags_0grade.gph" "$figures/Acelera_leads&lags_3grade.gph" "$figures/Acelera_leads&lags_4grade.gph" "$figures/Acelera_leads&lags_5grade.gph", cols(2) graphregion(fcolor(white)) ysize(7) xsize(9) title(, fcolor(white) size(medium) color(cranberry))
			graph export "$figures/Figure1.pdf", as(pdf) replace
			foreach grade in 0 3 4 5 {
			erase "$figures/Acelera_leads&lags_`grade'grade.gph"
			}
			*/
		}

		
		* __________________________________________________________________________________________________________________________________________________________ *

		**
		*Efeitos heterogeneos
		*-----------------------------------------------------------------------------------------------------------------------------------------------------------*
		{		
		estimates clear
		
		foreach outcome in approved  dropped {  //dropped 
			
			local i = 1
			
			**
			foreach grade in 0  { 
				if "`outcome' " ==  "approved" local title = "Approval"
				if "`outcome' " ==  "repeated" local title = "Repetition"
				if "`outcome' " ==  "dropped"  local title = "Dropout"
				
					foreach spec in D {
						
						use 	"$dtfinal/SE LIGA & Acelera_Recife.dta" if year < 2015, clear
						
						****--------------------------->>>
						drop if seliga2014 == 1
						****--------------------------->>>

						sample, grade(`grade') criteria_eleg(1) spec("`spec'") ultimo_ano(2014)
						
						
						
						eststo test`i', title("DiD")	   :  xtreg `outcome'  d_acelera  									i.codschool i.year i.grade i.gender students_class dif_idade_turma distorcao $schoolinfra 		[aw = _weight], cluster(cd_mat) fe  // aqui chegamos ate a considerar colocar apenas entrou_1ano, mas inflamos o efeito do tratamento porque comparamos quem entrou  (mas nao necessariamente era elegivel) com apenas controles elegiveis
						treated_control, test(`i') outcome(`outcome')
						local i = `i' + 1								
						
						foreach var of varlist gender dif_idade_turma distorcao {
							
							gen int_`var' 	   = d_acelera*`var'
							eststo test`i', title("DiD")	   :  xtreg `outcome'  d_acelera  int_`var' 						i.codschool i.year i.grade i.gender students_class dif_idade_turma distorcao $schoolinfra 		[aw = _weight], cluster(cd_mat) fe  // aqui chegamos ate a considerar colocar apenas entrou_1ano, mas inflamos o efeito do tratamento porque comparamos quem entrou  (mas nao necessariamente era elegivel) com apenas controles elegiveis
							treated_control, test(`i') outcome(`outcome')
							local i = `i' + 1							

						}
						
						eststo test`i', title("Leads-Lags"):  xtreg `outcome'  lag_0  			 lead_2 lead_1 lag_1 lag_2  i.codschool i.year i.grade i.gender students_class dif_idade_turma distorcao $schoolinfra       [aw = _weight], cluster(cd_mat) fe  // aqui chegamos ate a considerar colocar apenas entrou_1ano, mas inflamos o efeito do tratamento porque comparamos quem entrou  (mas nao necessariamente era elegivel) com apenas controles elegiveis
						treated_control, test(`i') outcome(`outcome')
						local i = `i' + 1							

						drop int_*
						foreach var of varlist gender dif_idade_turma distorcao {
							
							gen int_`var' 	   = lag_0*`var'
						
							
							eststo test`i', title("Leads-Lags"):  xtreg `outcome'  lag_0  int_`var'  lead_2 lead_1 lag_1 lag_2  i.codschool i.year i.grade i.gender students_class dif_idade_turma distorcao $schoolinfra       [aw = _weight], cluster(cd_mat) fe  // aqui chegamos ate a considerar colocar apenas entrou_1ano, mas inflamos o efeito do tratamento porque comparamos quem entrou  (mas nao necessariamente era elegivel) com apenas controles elegiveis
							treated_control, test(`i') outcome(`outcome')
							local i = `i' + 1
						}
					}
			}	
			if "`outcome'" == "approved" {
			estout * using "$tables/Table4.xls",  keep(lag_0* d_acelera* int*)  title("`title'")  label cells(b(star fmt(2)) se(fmt(2))) mgroups("Pooled" "3rd grade" "4th grade" "5th grade", pattern(1 0 0  1 0 0  1 0 0  1 0 0 )) starlevels(* 0.10 ** 0.05 *** 0.01) stats(N r2 unique_treat unique_control unique_school, labels("Obs" "R2" "Treated" "Comparison" "Num. schools") fmt(%9.0g %9.2f %9.2f)) replace
			}
			else{
			estout * using "$tables/Table4.xls",  keep(lag_0* d_acelera* int*)  title("`title'")  label cells(b(star fmt(2)) se(fmt(2))) mgroups("Pooled" "3rd grade" "4th grade" "5th grade", pattern(1 0 0  1 0 0  1 0 0  1 0 0 )) starlevels(* 0.10 ** 0.05 *** 0.01) stats(N r2 unique_treat unique_control unique_school, labels("Obs" "R2" "Treated" "Comparison" "Num. schools") fmt(%9.0g %9.2f %9.2f)) append
			}
			estimates clear			
		}
		}
		
		
		

	/*		
			

		
		keep 
		
		/*
		
		
		
		
		
		use 	"$dtfinal/SE LIGA & Acelera_Recife.dta" if year < 2015, clear	

			keep if none2014 == 1 & max_distorcao_turma > 1 //ou seja turmas com alunos elegiveis ao programa
			
			sort year cd_turma
			
			br 		cd_turma year cd_mat grade type_program  alunovaimigrar_acelera alunovaimigrar_seliga n_alunosvaomigrar_seliga n_alunosvaomigrar_acelera
			
			sort 	cd_mat year
			
			br 		cd_mat year cd_turma n_alunos_migraram_acelera n_alunos_migraram_seliga  if cd_mat == 4445570 | cd_mat == 5084482 | cd_mat == 5147166
			
			gen		id_ano_trat = 0 if (n_alunos_migraram_acelera + n_alunos_migraram_seliga == 0) | year < 2010
			
			replace id_ano_trat = 1 if (n_alunos_migraram_acelera + n_alunos_migraram_seliga  > 0) & year > 2009
			
			bys		cd_mat: egen treated = max(id_ano_trat)
						
			**Opcao1, se T = 1 mesmo depois de nao ter mais nenhum aluno migrando para um programa de aceleracao. 
			bys 	cd_mat:	egen  A = min(year) if id_ano_trat == 1
			
			bys 	cd_mat:	egen  min_ano_treated = min(A) 
			
			drop A
				
			replace id_ano_trat = 1 if (year > min_ano_treated) & treated == 1 & !missing(min_ano_treated)
				
			
			
			xtset cd_mat year
			
			gen a = total_migraram_sla*id_ano_trat 
			bys cd_turma: egen num_alunos_distorcao = sum(dist_1mais)
			
			xtreg approved  i.codschool i.year i.grade i.gender students_class dif_idade_turma distorcao $schoolinfra   num_alunos_distorcao id_ano_trat a, cluster(cd_mat) fe  // aqui chegamos ate a considerar colocar apenas entrou_1ano, mas inflamos o efeito do tratamento porque comparamos quem entrou  (mas nao necessariamente era elegivel) com apenas controles elegiveis
				
				
				
			
		use 	"$dtfinal/SE LIGA & Acelera_Recife.dta" if year < 2015, clear	
			
			keep if max_distorcao_turma > 1 
			
			collapse (mean) reprovou_anterior distorcao students_class dif_idade_turma  (sum)dist_2mais dist_1mais (max)total_migraram_sla, by(cd_turma codschool year grade)
			
			gen treated = total_migraram_sla > 0 & year > 2009
			
			
			psmatch2 treated reprovou_anterior distorcao students_class dif_idade_turma i.grade i.codschool i.year dist_2mais dist_1mais  , n(3) common ties
					
				
		
							tw kdensity _pscore if treated == 1 [aw = _weight],  lw(1.5) lp(dash) color(red) 				///
							///
							|| kdensity _pscore if treated == 0  [aw = _weight],  lw(thick) lp(dash) color(gs12) 			///
							graphregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 	///
							plotregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 	///
							ylabel(, labsize(small) angle(horizontal) format(%2.1fc)) 											///
							xlabel(, labsize(small) gmax angle(horizontal)) 													///
							ytitle("", size(medsmall))			 																///
							xtitle("Propensity score", size(medsmall)) 															///
							title("", pos(12) size(medsmall)) 																	///
							subtitle(, pos(12) size(medsmall)) 																	///
							ysize(5) xsize(7) 																					///
							legend(order(1 "T" 2 "C") pos(6) region(lstyle(none) fcolor(none)) size(medsmall))  ///
							note("", color(black) fcolor(background) pos(7) size(small)) 

						keep if _support == 1						
						keep if _weight != .
						
						keep cd_turma _weight
						tempfile   sample
						save      `sample'
		

		
		use 	"$dtfinal/SE LIGA & Acelera_Recife.dta" if year < 2015, clear	

			keep if none2014 == 1 & max_distorcao_turma > 1 //ou seja turmas com alunos elegiveis ao programa
			
			merge m:1 cd_turma using `sample', nogen keep(3)
			
			sort year cd_turma
			
			br 		cd_turma year cd_mat grade type_program  alunovaimigrar_acelera alunovaimigrar_seliga n_alunosvaomigrar_seliga n_alunosvaomigrar_acelera
			
			sort 	cd_mat year
			
			br 		cd_mat year cd_turma n_alunos_migraram_acelera n_alunos_migraram_seliga  if cd_mat == 4445570 | cd_mat == 5084482 | cd_mat == 5147166
			
			gen		id_ano_trat = 0 if (n_alunos_migraram_acelera + n_alunos_migraram_seliga == 0) | year < 2010
			
			replace id_ano_trat = 1 if (n_alunos_migraram_acelera + n_alunos_migraram_seliga  > 0) & year > 2009
			
			bys		cd_mat: egen treated = max(id_ano_trat)
						
			**Opcao1, se T = 1 mesmo depois de nao ter mais nenhum aluno migrando para um programa de aceleracao. 
			bys 	cd_mat:	egen  A = min(year) if id_ano_trat == 1
			
			bys 	cd_mat:	egen  min_ano_treated = min(A) 
			
			drop A
				
			replace id_ano_trat = 1 if (year > min_ano_treated) & treated == 1 & !missing(min_ano_treated)
				
			drop if year > min_ano_treated & treated == 1
			
			xtset cd_mat year
			
			gen a = total_migraram_sla *id_ano_trat 
			
			bys cd_turma: egen num_alunos_distorcao = sum(dist_1mais)

			xtreg approved  i.codschool i.year i.grade i.gender students_class dif_idade_turma distorcao $schoolinfra  id_ano_trat a num_alunos_distorcao, cluster(cd_mat) fe  // aqui chegamos ate a considerar colocar apenas entrou_1ano, mas inflamos o efeito do tratamento porque comparamos quem entrou  (mas nao necessariamente era elegivel) com apenas controles elegiveis
				
			xtreg dropped   i.codschool i.year i.grade i.gender students_class dif_idade_turma distorcao $schoolinfra  id_ano_trat a num_alunos_distorcao, cluster(cd_mat) fe  // aqui chegamos ate a considerar colocar apenas entrou_1ano, mas inflamos o efeito do tratamento porque comparamos quem entrou  (mas nao necessariamente era elegivel) com apenas controles elegiveis
				
				
			
			
			
			
			
			
				
				
				
				
			use 	"$dtfinal/SE LIGA & Acelera_Recife.dta" if year < 2015, clear	
			
				merge m:1 codschool year using "$dtinter/School Level Data.dta" , keepusing(alunos_1mais) keep(3) nogen
				
				gen	 	z =  alunos_1mais - 38  if year == 2010
				
				replace z =  alunos_1mais - 17  if year == 2011
				
				replace z =  alunos_1mais - 16  if year == 2012
				
				replace z =  alunos_1mais - 24  if year == 2013
				
				replace z =  alunos_1mais - 40  if year == 2014
				
				gen 	T = 1 if z >= 0
				replace T = 0 if z <  0 
				
				bys year: tab type_program T 

				xtset cd_mat year 
				xtivreg approved z (d_acelera = T )  i.codschool i.year i.grade i.gender students_class dif_idade_turma distorcao $schoolinfra ,  fe

	
				
				 if `grade' == 0	keep 		if ((el`criteria_eleg'_nesse_ano  == 1 & t_acelera == 1 & ja_participou_acelera == 0) | (el`criteria_eleg'_nesse_ano  == 1 & type_program == 1 & ja_participou_acelera == 0)) & year == `year' //pooled

				
				
				
				
			use 	"$dtfinal/SE LIGA & Acelera_Recife.dta" if year == 2014, clear	
			
			merge m:1 codschool year using "$dtinter/School Level Data.dta" , keepusing(alunos_1mais) keep(3) nogen

			keep 		if ((el1_nesse_ano  == 1 & t_acelera == 1 & ja_participou_acelera == 0) | (el1_nesse_ano  == 1 & type_program == 1 & ja_participou_acelera == 0))  

				
				
				gen z =  alunos_1mais - 40  if year == 2014
				
				gen 	T = 1 if z >= 0
				replace T = 0 if z <  0 
				
				
				

				ivregress 2sls  approved i.codschool i.year i.grade i.gender students_class dif_idade_turma distorcao $schoolinfra  z (t_acelera = T )  
				
				
				
				
				
				
				
				
				
				
				
				
				
			
				use "$dtinter/School Level Data.dta" if year< 2015 , clear
				
				gen	 	z =  alunos_1mais - 38  if year == 2010
				
				replace z =  alunos_1mais - 17  if year == 2011
				
				replace z =  alunos_1mais - 16  if year == 2012
				
				replace z =  alunos_1mais - 24  if year == 2013
				
				replace z =  alunos_1mais - 40  if year == 2014
				
				gen 	T = 1 if z >= 0
				replace T = 0 if z <  0 
		
				keep if year == 2014
				keep if inrange(z,-20,20)
					tw  (lpolyci approvalEF1t  z if z >= 0, kernel(triangle) degree(0) bw(4) acolor(gs12) fcolor(gs12) clcolor(gray) clwidth(0.3)) 		///
					(lpolyci approvalEF1t  z if z < 0, kernel(triangle) degree(0) bw(4) acolor(gs12) fcolor(gs12) clcolor(gray) clwidth(0.3)) 		///
					(scatter  approvalEF1t  z if z >= -20 & z <  0 ,  sort msymbol(circle) msize(small) mcolor(navy))         		 	///
					(scatter  approvalEF1t  z if z >=   0 & z <= 20, msymbol(circle) msize(small) mcolor(cranberry)), xline(0) 	///
					legend(off) 																									///
					plotregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 				///						
					title({bf:`: variable label `var''}, pos(11) color(navy) span size(medium))										///
					ytitle("%") xtitle("Age difference from the cutoff (in weeks)", size(small)) saving(short_`var'.gph, replace) 	/// 
					note("", color(black) fcolor(background) pos(7) size(small)) 

		
		
				
				 if `grade' == 0	keep 		if ((el`criteria_eleg'_nesse_ano  == 1 & t_acelera == 1 & ja_participou_acelera == 0) | (el`criteria_eleg'_nesse_ano  == 1 & type_program == 1 & ja_participou_acelera == 0)) & year == `year' //pooled

				
				
				
				
				
				
				
				
				
				
				
				
				
			**Opcao 2 , dropping no ano em que  T = 1 mesmo depois de nao ter mais nenhum aluno migrando para um programa de aceleracao. 
				
				
				
				
			bys cd_mat:	egen max_ano_treated = max(year) if id_ano_trat == 1
			
			
			
			
			
			

			
		/*
		
		
		
		
		
		
		
		
		
		
		
		
		use "$dtinter/trend_1_0.dta", clear
		
			foreach var of varlist approved repeated dropped {
				replace `var' = `var'*100
			}
				
			tw 	///
			(line approved year if t_acelera == 1, lwidth(0.5) color(gray) lp(solid) connect(direct) recast(connected) 	 													///  
			ml() mlabcolor(gs2) msize(1) ms(o) mlabposition(12)  mlabsize(2.5)) 																						///
			(line approved year if t_acelera == 0, lwidth(0.5) color(ebblue) lp(shortdash) connect(direct) recast(connected) 	 		///  
			ml() mlabcolor(gs2) msize(1) ms(o) mlabposition(12)  mlabsize(2.5)																							///
			ylabel(, labsize(small) gmax angle(horizontal) format(%4.0fc))											     												///
			yscale( alt )  																																				///
			xlabel(2008(1)2014, labsize(medsmall) gmax angle(horizontal) format(%4.1fc))											     								///
		    graphregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white))		 													///
			plotregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 															///						
			legend(order(1 "T"  2 "C"  ) pos(12) cols(3) size(medlarge) region(lwidth(none) color(white) fcolor(none))) 				///
			ysize(5) xsize(8) 																										 									///
			note(, span color(black) fcolor(background) pos(7) size(small)))  
			
			
			
			
			
			*graph export "$figures/time-trend-math.pdf", as(pdf) replace
			*graph export "$figures/Figure1a.pdf", as(pdf) replace
					
			
			
			
			
			
			
			
			
			
					
		/*

			use "$dtinter/trend_1_0_A.dta", clear
			
			
					foreach var of varlist approved repeated dropped {
				replace `var' = `var'*100
			}
				
			tw 	///
			(line approved year if T == 1 & ano_tratamento == 2010 , lwidth(0.5) color(gray) lp(solid) connect(direct) recast(connected) 	 													///  
			ml() mlabcolor(gs2) msize(1) ms(o) mlabposition(12)  mlabsize(2.5)) 																						///
			(line approved year if T == 0 & ano_tratamento == 2010 , lwidth(0.5) color(ebblue) lp(shortdash) connect(direct) recast(connected) 	 		///  
			ml() mlabcolor(gs2) msize(1) ms(o) mlabposition(12)  mlabsize(2.5)																							///
			ylabel(, labsize(small) gmax angle(horizontal) format(%4.0fc))											     												///
			yscale( alt )  																																				///
			xlabel(2008(1)2014, labsize(medsmall) gmax angle(horizontal) format(%4.1fc))											     								///
		    graphregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white))		 													///
			plotregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 															///						
			legend(order(1 "T"  2 "C"  ) pos(12) cols(3) size(medlarge) region(lwidth(none) color(white) fcolor(none))) 				///
			ysize(5) xsize(8) 																										 									///
			note(, span color(black) fcolor(background) pos(7) size(small)))  
			
			
			
		
		
		
		/*
		
		
			
			
			
			
			
			
			
			/*
			
			**
			*Pooled
			*-----------------------------------------------------------------------------------------------------------------------------------------------------------*
					**			
					xtreg `var' i.codschool i.year i.grade i.gender students_class dif_idade_turma distorcao $schoolinfra  d_acelera 						if 	(elegivel2_1ano == 1 & entrou2_1ano_acelera == 1) | (elegivel2_1ano == 1 & none == 1) | ///
																																										(elegivel2_2ano == 1 & entrou2_2ano_acelera == 1) | (elegivel2_2ano == 1 & none == 1) | /// 
																																										(elegivel2_3ano == 1 & entrou2_3ano_acelera == 1) | (elegivel2_3ano == 1 & none == 1) | /// 
																																										(elegivel2_4ano == 1 & entrou2_4ano_acelera == 1) | (elegivel2_4ano == 1 & none == 1) | /// 
																																										(elegivel2_5ano == 1 & entrou2_5ano_acelera == 1) | (elegivel2_5ano == 1 & none == 1) , cluster(cd_mat) fe
					eststo, title("Acelera, I")	
					
					**			
					xtreg `var' i.codschool i.year i.grade i.gender students_class dif_idade_turma distorcao $schoolinfra  t_acelera lead_1 lead_2			if 	(elegivel2_1ano == 1 & entrou2_1ano_acelera == 1) | (elegivel2_1ano == 1 & none == 1) | ///
																																										(elegivel2_2ano == 1 & entrou2_2ano_acelera == 1) | (elegivel2_2ano == 1 & none == 1) | /// 
																																										(elegivel2_3ano == 1 & entrou2_3ano_acelera == 1) | (elegivel2_3ano == 1 & none == 1) | /// 
																																										(elegivel2_4ano == 1 & entrou2_4ano_acelera == 1) | (elegivel2_4ano == 1 & none == 1) | /// 
																																										(elegivel2_5ano == 1 & entrou2_5ano_acelera == 1) | (elegivel2_5ano == 1 & none == 1) , cluster(cd_mat) fe
					eststo, title("Acelera, II")	
					

			**
			*Por serie
			*-----------------------------------------------------------------------------------------------------------------------------------------------------------*
				foreach grade in 3 4 5 { 
				

														
				}
				

		}
		
		
		//tentar deixar so elegivel e entrou ou elegivel. para manter so alunos com distorcao. 
		
		
		
		

	/*
	
	**
	*2a ideia
	
	
	*/
		
estimates clear




		foreach grade in 3 4 5 { 
		
		if  `grade' == 3 local title = "3rd grade"
		if  `grade' == 4 local title = "4th grade"
		if  `grade' == 5 local title = "5th grade"
					
					
			forvalues year = 2010(1)`ultimo_ano' { 

					use 	"$dtfinal/SE LIGA & Acelera_Recife.dta" if year == `year', clear
					
					if `year' > 2010 merge m:1 cd_mat using `keep', keep(1) nogen	//alunos que ainda náo foram achados na base de dados
					
						keep if ((el_`grade'ano == 1 & none == 1) | en_`grade'ano_`programa' == 1) & tem_`programa'_nesse_ano == 1
						
						replace cohort = `year'
						keep cd_mat cohort
						
						
						if `year' > 2010 append using `keep'
				
						tempfile keep
						save 	`keep'
				
				}		
		
			use 	"$dtfinal/SE LIGA & Acelera_Recife.dta" if year < 2015, clear
			drop cohort

				merge m:1 cd_mat using `keep', keep(3) keepusing(cohort)
		
					drop if sem_baseline == 1
					
							
					bys 	cd_mat: gen total = _N
					drop 	if		    total == 1
					estimates clear
					
					
					preserve
					replace cohort = . if none == 1
					collapse (mean)approved repeated dropped, by (year `programa' cohort )
					
					save "$dtinter/A`programa'`grade'.dta", replace
					
					restore
					
					**
					xtset cd_mat year	
					
					/*			
				foreach var of varlist approved repeated dropped { 
				

					
					xtreg `var' i.codschool i.year i.grade d_`programa' 						  , cluster(cd_mat) fe
					eststo, title("Se Liga, I")
					**
					xtreg `var' i.codschool i.year i.grade i.gender students_class dif_idade_turma $schoolinfra  d_`programa'  						  , cluster(cd_mat) fe
					eststo, title("Se Liga, II")
					
					xtreg `var' i.codschool i.year i.grade i.gender students_class dif_idade_turma $schoolinfra  d_`programa'0  d_`programa'1  d_`programa'2  , cluster(cd_mat) fe
					eststo, title("Se Liga, III")
				
				}
				
				
			if `grade' == 3 & "`programa'" == "seliga" {
			estout * using "$tables/dif_seliga.xls",  keep(d_*)  title("`title'") label mgroups("Approval" "Repetition" "Dropout", pattern(1 0 0 1 0 0 1 0 0)) cells(b(star fmt(2)) se(fmt(4))) starlevels(* 0.10 ** 0.05 *** 0.01) stats(N r2, labels("Obs" "R2") fmt(%9.0g %9.2f %9.2f)) replace
			}
			if `grade' != 3 & "`programa'" == "seliga" {
			estout * using "$tables/dif_seliga.xls",  keep(d_*)  title("`title'") label mgroups("Approval" "Repetition" "Dropout", pattern(1 0 0 1 0 0 1 0 0)) cells(b(star fmt(2)) se(fmt(4))) starlevels(* 0.10 ** 0.05 *** 0.01) stats(N r2, labels("Obs" "R2") fmt(%9.0g %9.2f %9.2f)) append
			}
			if `grade' == 3 & "`programa'" == "acelera" {
			estout * using "$tables/dif_acelera.xls",  keep(d_*)  title("`title'") label mgroups("Approval" "Repetition" "Dropout", pattern(1 0 0 1 0 0 1 0 0)) cells(b(star fmt(2)) se(fmt(4))) starlevels(* 0.10 ** 0.05 *** 0.01) stats(N r2, labels("Obs" "R2") fmt(%9.0g %9.2f %9.2f)) replace
			}
			if `grade' != 3 & "`programa'" == "acelera" {
			estout * using "$tables/dif_acelera.xls",  keep(d_*)  title("`title'") label mgroups("Approval" "Repetition" "Dropout", pattern(1 0 0 1 0 0 1 0 0)) cells(b(star fmt(2)) se(fmt(4))) starlevels(* 0.10 ** 0.05 *** 0.01) stats(N r2, labels("Obs" "R2") fmt(%9.0g %9.2f %9.2f)) append
			}			
			*/
			
			estimates clear

			
			}
	
			
				
				
				
				use "$dtinter/Aseliga3.dta", clear
				

		
		
		
	estimates clear


	foreach programa in acelera {

		foreach grade in 3 4 5 { 
		
		if  `grade' == 3 local title = "3rd grade"
		if  `grade' == 4 local title = "4th grade"
		if  `grade' == 5 local title = "5th grade"
		
		
		
			forvalues year = 2009(1)2013 { 

					use 	"$dtfinal/SE LIGA & Acelera_Recife.dta" if year == `year', clear
						
					if `year' > 2009 merge m:1 cd_mat using `keep', keep(1) nogen	//alunos que ainda náo foram achados na base de dados

						keep if  proxima_serie  == `grade'
						keep if ((none == 1 & distorcao > 1) | aluno_migrou_`programa'== 1) 
						psmatch2 aluno_migrou_`programa' i.gender  repeated distorcao i.codschool i.cd_turma, n(3) common ties
						
						
						keep cd_mat _id _n1 _treated _support _weight _pscore cohort
						
		
						preserve
						
						keep 	if _treated == 1 & _support == 1
						tempfile treated
						save 	`treated'
						
						restore
					
					
						preserve
						
						keep if _treated == 1 & _support == 1
						
						keep 	 _n1
						rename	 _n1 _id
						duplicates drop _id, force
						tempfile control
						save 	`control'
						
						restore
					
					
						merge 1:1 _id using `control', keep(3) nogen
				
						append using `treated'
						
						replace cohort = `year'

						if `year' > 2009 append using `keep'
						tempfile keep
						save `keep'
			}		
			
				use 	"$dtfinal/SE LIGA & Acelera_Recife.dta" if year < 2015, clear
				drop cohort

					merge m:1 cd_mat using `keep', keep(3) 
			
						drop if sem_baseline == 1
						
								
						bys 	cd_mat: gen total = _N
						drop 	if		    total == 1
						estimates clear
						
					preserve
					collapse (mean)approved repeated dropped, by (year `programa' cohort )
					
					save "$dtinter/A`programa'`grade'psm.dta", replace
					
					restore
						
					
					**
					xtset cd_mat year	
					gen w = 1/(1-_pscore)
					
							
				foreach var of varlist approved repeated dropped { 

					xtreg `var' i.codschool i.year i.grade d_`programa' 						[w = _weight]   , cluster(cd_mat) fe
					eststo, title("Se Liga, I")
					**
					xtreg `var' i.codschool i.year i.grade students_class dif_idade_turma $schoolinfra  d_`programa'  					[w = _weight]		  , cluster(cd_mat) fe
					eststo, title("Se Liga, II")
					
					xtreg `var' i.codschool i.year i.grade students_class dif_idade_turma $schoolinfra  d_`programa'0  d_`programa'1  d_`programa'2 	[w = _weight] , cluster(cd_mat) fe
					eststo, title("Se Liga, III")
								
					
				
				}
				
				
					if `grade' == 3 & "`programa'" == "seliga" {
					estout * using "$tables/dif_seligapsm.xls",  keep(d_*)  title("`title'") label mgroups("Approval" "Repetition" "Dropout", pattern(1 0 0 1 0 0 1 0 0)) cells(b(star fmt(2)) se(fmt(4))) starlevels(* 0.10 ** 0.05 *** 0.01) stats(N r2, labels("Obs" "R2") fmt(%9.0g %9.2f %9.2f)) replace
					}
					if `grade' != 3 & "`programa'" == "seliga" {
					estout * using "$tables/dif_seligapsm.xls",  keep(d_*)  title("`title'") label mgroups("Approval" "Repetition" "Dropout",pattern(1 0 0 1 0 0 1 0 0)) cells(b(star fmt(2)) se(fmt(4))) starlevels(* 0.10 ** 0.05 *** 0.01) stats(N r2, labels("Obs" "R2") fmt(%9.0g %9.2f %9.2f)) append
					}
					if `grade' == 3 & "`programa'" == "acelera" {
					estout * using "$tables/dif_acelerapsm.xls",  keep(d_*)  title("`title'") label mgroups("Approval" "Repetition" "Dropout", pattern(1 0 0 1 0 0 1 0 0))cells(b(star fmt(2)) se(fmt(4))) starlevels(* 0.10 ** 0.05 *** 0.01) stats(N r2, labels("Obs" "R2") fmt(%9.0g %9.2f %9.2f)) replace
					}
					if `grade' != 3 & "`programa'" == "acelera" {
					estout * using "$tables/dif_acelerapsm.xls",  keep(d_*)  title("`title'") label mgroups("Approval" "Repetition" "Dropout", pattern(1 0 0 1 0 0 1 0 0)) cells(b(star fmt(2)) se(fmt(4))) starlevels(* 0.10 ** 0.05 *** 0.01) stats(N r2, labels("Obs" "R2") fmt(%9.0g %9.2f %9.2f)) append
					}			
		
		}
		}
		
		
		
		
		/*
		
						
				use "$dtinter/Aacelera3psm.dta", clear

				foreach var of varlist approved repeated dropped {
					replace `var' = `var'*100
				}
				
			tw 	///
			(line approved year if cohort == 2010 , lwidth(0.5) color(gray) lp(solid) connect(direct) recast(connected) 	 													///  
			ml() mlabcolor(gs2) msize(1) ms(o) mlabposition(12)  mlabsize(2.5)) 																						///
			(line approved year if cohort == 2010, lwidth(0.5) color(red) lp(shortdash) connect(direct) recast(connected)  	 												 		///  
			ml() mlabcolor(gs2) msize(1) ms(o) mlabposition(3)  mlabsize(2.5)) 										 													///
			(line approved year if cohort == 2014, lwidth(0.5) color(ebblue) lp(shortdash) connect(direct) recast(connected) 	 		///  
			ml() mlabcolor(gs2) msize(1) ms(o) mlabposition(12)  mlabsize(2.5)																							///
			ylabel(, labsize(small) gmax angle(horizontal) format(%4.0fc))											     												///
			yscale( alt )  																																				///
			xlabel(2008(1)2014, labsize(medsmall) gmax angle(horizontal) format(%4.1fc))											     								///
		    graphregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white))		 													///
			plotregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 															///						
			legend(order(1 "Control"  2 "Tratado em 2010"  3 "Tratado em 2011" 4 "Tratado em 2012" 5 "Tratado em 2013" 6 "Tratado em 2014" ) pos(12) cols(3) size(medlarge) region(lwidth(none) color(white) fcolor(none))) 				///
			ysize(5) xsize(8) 																										 									///
			note("`note'", span color(black) fcolor(background) pos(7) size(small)))  
			*graph export "$figures/time-trend-math.pdf", as(pdf) replace
			*graph export "$figures/Figure1a.pdf", as(pdf) replace
		

		
		
		
		set matsize 10000
		
		
		
					use 	"$dtfinal/SE LIGA & Acelera_Recife.dta" if year == 2009, clear
					
						keep if  proxima_serie == 3
						keep if ((none == 1 & distorcao > 1) | aluno_migrou_seliga == 1) 
						
						psmatch2 aluno_migrou_seliga repeated distorcao i.codschool i.cd_turma, n(1) common ties
			
			
		
										tw kdensity _pscore if aluno_migrou_seliga  == 1 [aw = _weight],  lw(thick) lp(dash) color(emidblue) 					///
										///
										|| kdensity _pscore if aluno_migrou_seliga == 0 [aw = _weight],  lw(thick) lp(dash) color(gs12) 						///
											graphregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 	///
											plotregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 	///
											ylabel(, labsize(small) angle(horizontal) format(%2.1fc)) 											///
											xlabel(, labsize(small) gmax angle(horizontal)) 													///
											ytitle("", size(medsmall))			 																///
											xtitle("Propensity score", size(medsmall)) 															///
											title("", pos(12) size(medsmall)) 																	///
											subtitle(, pos(12) size(medsmall)) 																	///
											ysize(5) xsize(7) 																					///
											legend(order(1 "Treated communes" 2 "Comparison communes") pos(6) region(lstyle(none) fcolor(none)) size(medsmall))  ///
											note("Source: Author's estimate based on Moroccan High Comission for Planning (HCP).", color(black) fcolor(background) pos(7) size(small)) 
											*graph export "$figures/Matching/matching_ipf_matched_sample_analysis`analysis'_neighbor`neighbor'_morocco.pdf", as(pdf) replace
		
		
					*/
					
					
					use 	"$dtfinal/SE LIGA & Acelera_Recife.dta" , clear
		
					
					
					use 	"$dtfinal/SE LIGA & Acelera_Recife.dta", clear	
						
						merge m:1 cd_mat using `amostra', keep(3) nogen
					
		
		
		
		/*			
				foreach var of varlist approved repeated dropped { 
				

					
					xtreg `var' i.codschool i.year i.grade d_`programa' 						  , cluster(cd_mat) fe
					eststo, title("Se Liga, I")
					**
					xtreg `var' i.codschool i.year i.grade i.gender students_class dif_idade_turma $schoolinfra  d_`programa'  						  , cluster(cd_mat) fe
					eststo, title("Se Liga, II")
					
					xtreg `var' i.codschool i.year i.grade i.gender students_class dif_idade_turma $schoolinfra  d_`programa'0  d_`programa'1  d_`programa'2  , cluster(cd_mat) fe
					eststo, title("Se Liga, III")
				
				}
				
				
			if `grade' == 3 & "`programa'" == "seliga" {
			estout * using "$tables/dif_seliga.xls",  keep(d_*)  title("`title'") label mgroups("Approval" "Repetition" "Dropout", pattern(1 0 0 1 0 0 1 0 0)) cells(b(star fmt(2)) se(fmt(4))) starlevels(* 0.10 ** 0.05 *** 0.01) stats(N r2, labels("Obs" "R2") fmt(%9.0g %9.2f %9.2f)) replace
			}
			if `grade' != 3 & "`programa'" == "seliga" {
			estout * using "$tables/dif_seliga.xls",  keep(d_*)  title("`title'") label mgroups("Approval" "Repetition" "Dropout", pattern(1 0 0 1 0 0 1 0 0)) cells(b(star fmt(2)) se(fmt(4))) starlevels(* 0.10 ** 0.05 *** 0.01) stats(N r2, labels("Obs" "R2") fmt(%9.0g %9.2f %9.2f)) append
			}
			if `grade' == 3 & "`programa'" == "acelera" {
			estout * using "$tables/dif_acelera.xls",  keep(d_*)  title("`title'") label mgroups("Approval" "Repetition" "Dropout", pattern(1 0 0 1 0 0 1 0 0)) cells(b(star fmt(2)) se(fmt(4))) starlevels(* 0.10 ** 0.05 *** 0.01) stats(N r2, labels("Obs" "R2") fmt(%9.0g %9.2f %9.2f)) replace
			}
			if `grade' != 3 & "`programa'" == "acelera" {
			estout * using "$tables/dif_acelera.xls",  keep(d_*)  title("`title'") label mgroups("Approval" "Repetition" "Dropout", pattern(1 0 0 1 0 0 1 0 0)) cells(b(star fmt(2)) se(fmt(4))) starlevels(* 0.10 ** 0.05 *** 0.01) stats(N r2, labels("Obs" "R2") fmt(%9.0g %9.2f %9.2f)) append
			}			
			*/
			
			estimates clear

			
			}
	}		
				
		
		
		
		
		
	/*	
		
		

	forvalues year = 2008(1)2014 { 

		use 	"$dtfinal/SE LIGA & Acelera_Recife.dta" if year == `year', clear
		
		if `year' > 2008 merge m:1 cd_mat using `merged', keep(1) nogen	keepusing(cd_mat)	//alunos que ainda náo foram achados na base de dados
		
			replace 	cohort = "3" + "`year'" if grade == 3 & (el_3ano == 1 & none == 1) | en_3ano_seliga == 1
			replace 	cohort = "4" + "`year'" if grade == 4 & (el_4ano == 1 & none == 1) | en_4ano_seliga == 1
			replace 	cohort = "5" + "`year'" if grade == 5 & (el_5ano == 1 & none == 1) | en_5ano_seliga == 1
			keep if 	cohort != ""
			keep 		cohort cd_mat
			tempfile 	`year'
			save       ``year''
			
			use 	"$dtfinal/SE LIGA & Acelera_Recife.dta", clear
				merge	   m:1  cd_mat using ``year'', keep(3) nogen
				duplicates drop cd_mat, force
				keep 			cd_mat cohort 
			if `year' > 2008 append using `merged'
				tempfile		   merged
				save 	   		  `merged'
	
	}		

	use 	"$dtfinal/SE LIGA & Acelera_Recife.dta" if year < 2015, clear

	merge m:1 cd_mat using `merged', keepusing(cd_mat cohort) keep(3) 
	
	keep if none == 1 | (sla == 1 & sem_baseline == 0)
	
	keep if num_vezes_painel > 1
	
	egen cod_cohort = group(cohort)
	
	
	xtset cd_mat year
	
	sort cd_mat year
	
	keep in 1/1002
	
	xtreg approved t_seliga i.codschool i.year if substr(cohort, 1, 1) == "3", fe
	xtreg approved t_seliga i.codschool i.year if substr(cohort, 1, 1) == "4", fe
	xtreg approved t_seliga i.codschool i.year if substr(cohort, 1, 1) == "5", fe
	
		

	
	
	
	
	
	
	
	
	
	
	
	
	
	
use "$censoescolar/School Infrastructure at school level.dta", clear

foreach var of varlist EnergyAccess SewerAccess WaterAccess Computer Library ComputerLab ScienceLab SportCourt InternetAccess SchoolEmployees BroadBandInternet {
	di as red "`var'"
	tab year	
	tab year if `var' != .
}

















	
	
		use 	"$dtfinal/SE LIGA & Acelera_Recife.dta" if year < 2015, clear
	
	replace
	
	keep 	if inlist(type_program, 2, 3)
	 
	tab 	type_program grade if grade > 2 & grade < 6    
	tab 	ja_participou_seliga if type_program == 2 & grade == 5	
		
		
	

	
	/*
	
use 	"$dtfinal/SE LIGA & Acelera_Recife.dta", clear
	
	keep 	if year == 2009
	
	gen 	cohort = "1" + "2009" if grade == 1
	
	replace cohort = "2" + "2009" if grade == 2
	
	replace cohort = "3" + "2009" if grade == 3
	
	replace cohort = "4" + "2009" if grade == 4
	
	replace cohort = "5" + "2009" if grade == 5
	
	keep if cohort != ""
	
	
	keep 	cd_mat grade cohort
	
	tempfile 2009
	save    `2009'
	
	

	
	
	

xtset cd_mat year

xtreg approved i.year i.grade i.codschool distorcao t_seliga if distorcao > 1, fe
	
	
	
	

	use "$dtfinal/SE LIGA & Acelera_Recife.dta"	if year == 2010, clear
		
	keep if tem_programa_nesse_ano == 1																			//escolas que ofereceram o programa em 2010
	
	keep if grade == 5	& (el_5ano == 1 | en_5ano == 1) & (type_program == 1 | type_program == 2)				//alunos de 3o ano elegiveis ou que entraram no se liga ou acelera. 
	
	
	keep 	cd_mat
	
	tempfile participantes
	
	save 	`participantes'
	
	use "$dtfinal/SE LIGA & Acelera_Recife.dta" if inrange(year, 2008, 2010), clear
	merge m:1 cd_mat using `participantes', keep(3)
	
	
	xtset cd_mat year

	xtreg approved i.year i.codschool distorcao  d_seliga , fe

	xtreg dropped  i.year i.codschool distorcao  d_seliga , fe

	xtreg repeated i.year i.codschool distorcao  d_seliga , fe

		
	
	
	
	
	
	
	
	
	
	
	
	
	
		
		sort 	cd_mat year
		
		keep if inrange(year, 2008, 2010)
		
		xtset cd_mat year

		xtreg approved i.year i.codschool distorcao  d_seliga i.grade if (elegivel_3ano == 1 | entrou_3ano == 1) , fe

		xtreg approved i.year i.codschool distorcao  d_seliga if (elegivel_4ano == 1 | entrou_4ano == 1), fe

		xtreg approved i.year i.codschool distorcao  d_seliga if (elegivel_5ano == 1 | entrou_5ano == 1), fe

		
		
		
		
		xtreg approved i.year i.codschool distorcao  d_acelera if (elegivel_3ano == 1 | entrou_3ano == 1), fe

		xtreg approved i.year i.codschool distorcao  d_acelera if (elegivel_4ano == 1 | entrou_4ano == 1), fe

		xtreg approved i.year i.codschool distorcao  d_acelera if (elegivel_5ano == 1 | entrou_5ano == 1), fe
		
		
				
		
		
		
				br 		cd_mat year codschool grade idade distorcao type_program status t_seliga t_acelera d_seliga d_acelera elegivel_5ano entrou_5ano sem_baseline num_vezes_painel if e(sample) == 1
				
		
		
		
		
		
		
		
		
		
		br 		cd_mat year codschool grade idade distorcao type_program status t_seliga t_acelera d_seliga d_acelera elegivel_3ano entrou_3ano Dlag* sem_baseline num_vezes_painel if elegivel_3ano == 1 | entrou_3ano == 1
		
	//exclusão de alunos que só aparecem uma vez na base de dados
		
		

		
		xtset cd_mat year
	
	
		xtreg approved i.year i.codschool distorcao i.gender d_seliga if (elegivel_3ano == 1 & none == 1) | entrou_3ano == 1), fe
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		xtreg approved i.year i.codschool  d_seliga, fe
		
		
		
	
		xtreg approved t_acelera i.year i.codschool, fe
	








	
	use "$dtfinal/SE LIGA & Acelera_Recife.dta" if  grade < 6 & year < 2015, clear

	sort cd_mat year
	
	keep if (year == 2009 & cd_mat[_n] == cd_mat[_n+1] & elegivel_nesse_ano[_n]   == 1) | ///
			(year == 2010 & cd_mat[_n] == cd_mat[_n-1] & elegivel_nesse_ano[_n-1] == 1) | ///
			(year == 2010 & cd_mat[_n] == cd_mat[_n+1] & elegivel_nesse_ano[_n]   == 1) | ///
			(year == 2011 & cd_mat[_n] == cd_mat[_n-1] & elegivel_nesse_ano[_n-1] == 1) | ///
			(year == 2011 & cd_mat[_n] == cd_mat[_n+1] & elegivel_nesse_ano[_n]   == 1) | ///
			(year == 2012 & cd_mat[_n] == cd_mat[_n-1] & elegivel_nesse_ano[_n-1] == 1) | ///
			(year == 2012 & cd_mat[_n] == cd_mat[_n+1] & elegivel_nesse_ano[_n]   == 1) | ///
			(year == 2013 & cd_mat[_n] == cd_mat[_n-1] & elegivel_nesse_ano[_n-1] == 1) | ///
			(year == 2013 & cd_mat[_n] == cd_mat[_n+1] & elegivel_nesse_ano[_n]   == 1) | ///
			(year == 2014 & cd_mat[_n] == cd_mat[_n-1] & elegivel_nesse_ano[_n-1] == 1)
	
	tab year type_program
	
	xtset cd_mat year
	
	xtreg approved t_seliga i.year i.codschool, fe
	
	xtreg approved t_acelera i.year i.codschool, fe
	
	
	
	
	
	/*
	
	set matsize 11000

	*REGRESSÕES
	* --------------------------------------------------------------------------------------------------------- *
		use "$dtfinal/SE LIGA & Acelera_Recife.dta", clear
		keep if ultima_serie_painel > 5
		
		
		keep if grade == 5 & (none == 1 | year == min_first_sla)
	

		*bys cd_mat: egen min_ano = min(year) 
		*keep if (year == min_ano & none == 1) 

		psmatch2 t_sla distorcao i.status_anterior i.codschool i.year, n(1) common ties
		

									
										tw kdensity _pscore if sla == 1 [aw = _weight],  lw(1.5) lp(dash) color(red) 					///
										///
										|| kdensity _pscore if sla == 0 [aw = _weight],  lw(thick) lp(dash) color(gs12) 						///
											graphregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 	///
											plotregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 	///
											ylabel(, labsize(small) angle(horizontal) format(%2.1fc)) 											///
											xlabel(, labsize(small) gmax angle(horizontal)) 													///
											ytitle("", size(medsmall))			 																///
											xtitle("Propensity score", size(medsmall)) 															///
											title("", pos(12) size(medsmall)) 																	///
											subtitle(, pos(12) size(medsmall)) 																	///
											ysize(5) xsize(7) 																					///
											legend(order(1 "Treated communes" 2 "Comparison communes") pos(6) region(lstyle(none) fcolor(none)) size(medsmall))  ///
											note("Source: Author's estimate based on Moroccan High Comission for Planning (HCP).", color(black) fcolor(background) pos(7) size(small)) 

			
			bys cd_mat: egen w = max(_weight)
			duplicates drop cd_mat, force
			
			keep if _weight != .
			tempfile merged
			save `merged'
	
	
* --------------------------------------------------------------------------------------------------------- *
*REGRESSÕES
* --------------------------------------------------------------------------------------------------------- *
	use "$dtfinal/SE LIGA & Acelera_Recife.dta", clear	
		*merge m:1 cd_mat using `merged', keep(3) keepusing(w)
			
			

		* ------------------------------------------------------------------------------------------------- *
		xtset cd_mat year
		xtreg approved i.grade i.year i.codschool  lag* t_acelera lead*, fe vce(robust)

	
		* ------------------------------------------------------------------------------------------------- *
		matrix A = r(table)
		local col_final   = colsof(A) - 1
		local col_inicial = colsof(A) - 11
		clear
		svmat A
		drop in 9
		drop in 8
		drop in 7
		drop in 4
		drop in 3
		drop in 2
		keep A`col_inicial'- A`col_final'
		
		xpose, clear
		gen tempo = _n

		replace tempo = 0 if tempo == 7
		replace tempo = tempo[_n-1] - 1 if tempo > 7

		replace v1 = v1*100
		replace v2 = v2*100
		replace v3 = v3*100
		
		drop if tempo < - 2 | tempo > 4
		drop if tempo == -2

			set scheme economist
			twoway ///
			(line v1 tempo if tempo <  1, ml(v1) msymbol(O) msize(medium) color(cranberry)) 					///
			(line v1 tempo if tempo >= 1, ml(v1) msymbol(D) msize(medium) color(emidblue)) 						///
			(rcap v2 v3 tempo, lcolor(navy)																		///
			yline(0, lp(shortdash) lcolor(cranberry)) 															///
			xline(0, lp(shortdash) lcolor(cranberry)) 															///
			graphregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 	///
			plotregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 	///
			ylabel(, labsize(medsmall) format(%2.1fc)) 													///
			xlabel(-1(1)4, labsize(medsmall) gmax angle(horizontal)) 											///
			yscale(alt)																							///
			ytitle("Variation in the approval rate, in pp", size(medium))			 							///
			xtitle("") ///
			title("5{sup:th} grade", pos(12) size(large)) 																	///
			subtitle(, pos(12) size(medsmall)) 																	///
			text(-2 0.5 "Intervention", size(large)) ///
			ysize(5) xsize(7) 																					///
			legend(order(1 "Before intervention" 2 "During and after intervention") pos(6) size(medium) region(lwidth(none) color(none))))  								
			*graph export "$figures/SLA_5oano_aprovação.pdf", as(pdf) replace	



	
	
	/*
	



 
* --------------------------------------------------------------------------------------------------------- *
*REGRESSÕES
* --------------------------------------------------------------------------------------------------------- *
	use 	"$dtfinal/SE LIGA & Acelera_Recife.dta", clear
	drop if  num_vezes_painel == 1 | sem_baseline == 1
	
			forvalues i = 3(1)5 {
				su approved if el_`i'ano == 0 & grade == `i'
				su approved if el_`i'ano == 1 & grade == `i'
			}
			
		keep if none == 1 | twoprograms == 1 | only_seliga == 1 | only_acelera == 1
		keep if elegivel_3ano == 1 | entrou_3ano == 1 
			
		* ------------------------------------------------------------------------------------------------- *
		xtset cd_mat year
		xtreg approved i.codschool i.year Dlag* Dlead* i.grade , fe vce(robust)

	
		* ------------------------------------------------------------------------------------------------- *
		matrix A = r(table)
		local col_final   = colsof(A) - 1
		local col_inicial = colsof(A) - 11
		clear
		svmat A
		drop in 9
		drop in 8
		drop in 7
		drop in 4
		drop in 3
		drop in 2
		keep A`col_inicial'- A`col_final'
		
		xpose, clear
		gen tempo = _n

		replace tempo = 0 if tempo == 7
		replace tempo = tempo[_n-1] - 1 if tempo > 7

		replace v1 = v1*100
		replace v2 = v2*100
		replace v3 = v3*100
		
		drop if tempo < - 2 | tempo > 4
		drop if tempo == -2

			set scheme economist
			twoway ///
			(line v1 tempo if tempo <  1, ml(v1) msymbol(O) msize(medium) color(cranberry)) 					///
			(line v1 tempo if tempo >= 1, ml(v1) msymbol(D) msize(medium) color(emidblue)) 						///
			(rcap v2 v3 tempo, lcolor(navy)																		///
			yline(0, lp(shortdash) lcolor(cranberry)) 															///
			xline(0, lp(shortdash) lcolor(cranberry)) 															///
			graphregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 	///
			plotregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 	///
			ylabel(, labsize(medsmall) format(%2.1fc)) 													///
			xlabel(-1(1)4, labsize(medsmall) gmax angle(horizontal)) 											///
			yscale(alt)																							///
			ytitle("Variation in the approval rate, in pp", size(medium))			 							///
			xtitle("") ///
			title("5{sup:th} grade", pos(12) size(large)) 																	///
			subtitle(, pos(12) size(medsmall)) 																	///
			text(-2 0.5 "Intervention", size(large)) ///
			ysize(5) xsize(7) 																					///
			legend(order(1 "Before intervention" 2 "During and after intervention") pos(6) size(medium) region(lwidth(none) color(none))))  								
			graph export "$figures/SLA_5oano_aprovação.pdf", as(pdf) replace	
			graph export "$figures/SLA_5oano_aprovação.png", as(png) replace	



		/*
		* __________________________________________________________________________________________________________________________________________________________ *
		**
		**
		*Table 2, efeito por serie DiD and lead and lags
		*-----------------------------------------------------------------------------------------------------------------------------------------------------------*
		**
		estimates clear
	
		foreach outcome of varlist approved dropped  {  //dropped 
			local i = 1
			**
			foreach grade in 0 3 4 5 { 
				
				if "`outcome' " ==  "approved" local title = "Approval"
				if "`outcome' " ==  "repeated" local title = "Repetition"
				if "`outcome' " ==  "dropped"  local title = "Dropout"
				
				
				
					foreach spec in D {
						
						use 	"$dtfinal/SE LIGA & Acelera_Recife.dta" if year < 2015, clear
						
						****--------------------------->>>
						drop if seliga2014 == 1
						****--------------------------->>>

						sample, grade(`grade') criteria_eleg(1) spec("`spec'") ultimo_ano(2014)
						
							eststo test`i', title("DiD")		:  xtreg `outcome'  i.codschool i.year i.grade i.gender students_class dif_idade_turma distorcao $schoolinfra d_acelera											[aw = _weight], cluster(cd_mat) fe  // aqui chegamos ate a considerar colocar apenas entrou_1ano, mas inflamos o efeito do tratamento porque comparamos quem entrou  (mas nao necessariamente era elegivel) com apenas controles elegiveis
							treated_control, test(`i') outcome(`outcome')
							local i = `i' + 1
							
							eststo test`i', title("Leads, lags"):  xtreg `outcome'  i.codschool i.year i.grade i.gender students_class dif_idade_turma distorcao $schoolinfra lead_3 lead_2 lead_1  lag_0 lag_1 lag_2 lag_3	    [aw = _weight], cluster(cd_mat) fe  // aqui chegamos ate a considerar colocar apenas entrou_1ano, mas inflamos o efeito do tratamento porque comparamos quem entrou  (mas nao necessariamente era elegivel) com apenas controles elegiveis
							treated_control, test(`i') outcome(`outcome')
							local i = `i' + 1
					}
			}
				
			if "`outcome'" == "approved" {
			estout * using "$tables/Table2.xls",  keep(d_acelera lag_0)  title("`title'")  label mgroups("Pooled" "3rd grade" "4th grade" "5th grade", pattern(1 0 1 0 1 0 1 0)) cells(b(star fmt(2)) se(fmt(2))) starlevels(* 0.10 ** 0.05 *** 0.01) stats(N r2 space unique_treat outcome_treat space unique_control outcome_control unique_school  , labels("Obs" "R2" "Treated Group" "Students" "Mean outcome" "Comparison Group" "Students" "Mean outcome"  "Num. schools") fmt(%9.0g %9.2f %9.2f)) replace
			}
			else{
			estout * using "$tables/Table2.xls",  keep(d_acelera lag_0)  title("`title'")  label mgroups("Pooled" "3rd grade" "4th grade" "5th grade", pattern(1 0 1 0 1 0 1 0)) cells(b(star fmt(2)) se(fmt(2))) starlevels(* 0.10 ** 0.05 *** 0.01) stats(N r2 space unique_treat outcome_treat space unique_control outcome_control unique_school  , labels("Obs" "R2" "Treated Group" "Students" "Mean outcome" "Comparison Group" "Students" "Mean outcome"  "Num. schools") fmt(%9.0g %9.2f %9.2f)) append
			}
			estimates clear		
		}



	
	
	
	use "$dtinter/School Level Data.dta"  , clear
	
	

				tw  (lpolyci approvalEF1t dist_1mais if dist_1mais >= 16, kernel(triangle) degree(0) bw(40) acolor(gs12) fcolor(gs12) clcolor(gray) clwidth(0.3)) 		///
					(lpolyci approvalEF1t dist_1mais if dist_1mais<  16, kernel(triangle) degree(0) bw(40)  acolor(gs12) fcolor(gs12) clcolor(gray) clwidth(0.3)) 		///
					(scatter approvalEF1t dist_1mais if dist_1mais >= 0 & dist_1mais <  16 ,  sort msymbol(circle) msize(small) mcolor(navy))         		 	///
					(scatter approvalEF1t dist_1mais if dist_1mais >=  16 & dist_1mais <= 32,  sort msymbol(circle) msize(small) mcolor(cranberry)), 	///
					legend(off) 																								///
					plotregion(color(white) fcolor(white) lcolor(white) icolor(white) ifcolor(white) ilcolor(white)) 			///						
					ytitle("%") xtitle("Age difference from the cutoff (in months)") 											/// 
					note("", color(black) fcolor(background) pos(7) size(small))

	
	
	
	
				
			
				gen 	erro   = none == 0 & primeiro_ano_painel == min_first_acelera			 							// alunos cujo 1o ano na base é o ano de entrada no programa
				gen 	acerto = none == 0 & year < min_first_acelera & (status == 1 | status == 2 | status == 3)			// aluno tem baseline. Também não tem baseline se, embora apareça na base de dados antes de participar do type_program, não tem status de aprovado, reprovado ou abandono no ano anterior
				bys 	cd_mat: egen max_acerto = max(acerto)
				replace erro = 1 if none == 0 & max_acerto == 0 
			
				*Alunos sem baseline. PRECISA SER AQUI O CODIGO NAO MOVER PARA CIMA
				bys 	cd_mat: egen sem_baseline = max(erro)
				drop 	erro acerto max_acerto	
