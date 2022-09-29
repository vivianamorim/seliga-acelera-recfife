

	estimates clear 
	
	
	**PROGRAMA PARA CALCULAR O NUMERO DE TRATAMENTOS E DE CONTROLE
	* _____________________________________________________________________________________________________________________________________________________________ *
	{
	cap program drop treated_control
	program define   treated_control
	syntax, test(string) outcome(varlist)
		
		unique cd_mat    if e(sample) == 1 & acelera2018 == 1						
		scalar unique_treat  = r(unique)
				
		unique cd_mat    if e(sample) == 1 & acelera2018 == 0						//number of schools in the control group
		scalar unique_control = r(unique)
				
		unique codschool if e(sample) == 1 											//number of schools in the control group
		scalar unique_school = r(unique)
		
		su `outcome' if acelera2018 == 1 & grade == 3 & e(sample) == 1
		scalar outcome_treat = r(mean)
		scalar sd_treat		 = r(sd)
		
		su `outcome' if acelera2018 == 0 & grade == 3 & e(sample) == 1
		scalar outcome_control = r(mean)
		
		estadd scalar unique_control   = unique_control  : test`test'
		estadd scalar unique_treat	   = unique_treat    : test`test'
		estadd scalar unique_school	   = unique_school   : test`test'
		estadd scalar outcome_treat    = outcome_treat   : test`test'		
		estadd scalar outcome_control  = outcome_control : test`test'
		estadd scalar sd_treat	  	   = sd_treat	     : test`test'
		
	end
	}


	
	**REGRESSIONS OF THE EFFECTS OF ACELERA ON PERFORMANCE
	* _____________________________________________________________________________________________________________________________________________________________ *
	
	estimates clear

	foreach sub in 3 4 {
	
		use 	"$dtfinal/SE LIGA & Acelera_Recife.dta", clear

		**
		*Preparing data
		*---------------------------------------------------------------------------------------------------------------------------------------------------------- *
		{
		if `sub' == 1 local subject = "prof_LP_stand"
		if `sub' == 2 local subject = "prof_MT_stand"
		if `sub' == 3 local subject = "insuf_mat"
		if `sub' == 4 local subject = "insuf_port"
		
		*bys 		cd_mat: egen 	ultima_vez_3ano   	= max(year) 	if grade == 3  & `subject' != .	&  ja_participou_acelera == 0						//ultima   vez desse ano no 3o ano
		*bys 		cd_mat: egen 	primeira_vez_5ano 	= min(year) 	if grade == 5  & `subject' != .	& (ja_participou_acelera == 1 | none2018 == 1)		//primeira vez desse ano no 5o ano
		bys 		cd_mat: egen 	ultima_vez_3ano   	= max(year) 	if grade == 3  & `subject' != .				//ultima   vez desse ano no 3o ano
		bys 		cd_mat: egen 	primeira_vez_5ano 	= min(year) 	if grade == 5  & `subject' != .				//primeira vez desse ano no 5o ano
	
		bys 		cd_mat: gen 	Atem_3ano 			= 1 			if grade == 3
		bys 		cd_mat: gen 	Atem_5ano 			= 1 			if grade == 5
		bys 		cd_mat: egen 	tem_3ano  			= max(Atem_3ano)
		bys 		cd_mat: egen 	tem_5ano  			= max(Atem_5ano)
		bys			cd_mat: egen 	tem_prof3ano 	    = max(ultima_vez_3ano  ) 
		bys 		cd_mat: egen 	tem_prof5ano 	    = max(primeira_vez_5ano)
		
		replace 	tem_prof3ano 	= 1 								if tem_prof3ano !=.
		replace 	tem_prof3ano 	= 0 								if tem_prof3ano == .
		replace 	tem_prof5ano 	= 1	 								if tem_prof5ano !=.
		replace 	tem_prof5ano 	= 0 								if tem_prof5ano == .
		replace 	tem_5ano = 0 										if tem_5ano == . & pulou2_program3 != 1			//o aluno nao tem 5 ano, mas nao foi porque ele pulou duas series porque pulou2_program3 !=1
		
		gen 		tem_prof3e5ano  = 1 if (tem_prof3ano == 1 & tem_prof5ano == 1)
		replace 	tem_prof3e5ano  = 0 if 										 	tem_prof3e5ano != 1
		replace 	pulou2_program3 = 0 if pulou1_program3 == 1 | status == 2 | status  == 3
	
		
		preserve
		//entre os alunos do 4 ano que participaram do acelera, tem muitos que nao fizeram o exame de prof no 5 ano. Por que? 
			*-> uma explicacao seria que os piores alunos nao foram enviados para fazer a prova.
			*-> outra explicacao seria que os alunos do quarto ano pularam duas series (indo para o 6o ano) e portanto nao fizeram a prova. 
			*-> outra explicacao poderia ser porque esses alunos que nao fizeram a prova repetiram de ano. 
		if `sub' == 1 {
		keep  							if grade 	== 4   & t_acelera == 1			//comparando alunos de 4 anos com acelera
		replace 	pulou2_program3 = pulou2_program3*100
		iebaltab 	distorcao approved repeated prof_LP3ano prof_MT3ano pulou2_program3, format(%12.2fc) grpvar(tem_prof5ano) fixedeffect(year)   save("$tables/Fourfh-graders.xlsx") rowvarlabels replace 
		}
		restore
		
		tempfile data
		save 	`data'
		}
	
		
		**
		*Regressions
		*---------------------------------------------------------------------------------------------------------------------------------------------------------- *
		foreach amostra in  0 1 { //0-> All schools, 1-> only Acelera schools
				
			use `data', clear
					
				if `amostra' == 1 keep if acelera_school == 1
					
					**
					*----------------------------------->>
					*Alunos que entraram no Acelera no 4o ano. 
					{
						preserve
							bys 		cd_mat: egen A					  = min(year) if t_acelera == 1		
							bys 		cd_mat: egen primeiro_ano_acelera = max(A) 	
							keep 		if year  ==  primeiro_ano_acelera
							keep 		if grade == 4																	//todos os alunos cujo 1o ano no acelera eh no 4o ano do EF. 
							
							*keep if seliga2018 == 0
						
							gen 		distorcao4ano 			= distorcao
							gen 		students_class4ano 	    = students_class
							keep 				cd_mat year type_program codschool acelera_school tem_prof3ano tem_prof5ano tem_prof3e5ano grade distorcao4ano students_class4ano pulou2_program3 tem_3ano tem_5ano
						
							tempfile mat
							save 	`mat'
						restore
					}
					
					
					**
					*----------------------------------->>
					*Alunos elegiveis ao Acelera no 4o ano. 
					{
						preserve
							keep		 if none2018 == 1 & el1_4ano == 1 & grade == 4									//aqui sao os alunos que nunca participaram do se liga ou acelera e que eram elegiveis ao programa no 4 ano
							duplicates	 drop cd_mat, force
							gen 		distorcao4ano 			= distorcao
							gen 		students_class4ano 	    = students_class
							keep 			  	cd_mat year type_program codschool acelera_school tem_prof3ano tem_prof5ano tem_prof3e5ano grade distorcao4ano students_class4ano pulou2_program3 tem_3ano tem_5ano
							append 			using `mat'
							tempfile 			   mat
							save 				  `mat'		//amostra total
						restore
					}	
					
					
					**
					*----------------------------------->>
					*Amostra-> numero de alunos com prof no 3o ano, numero de alunos com prof no 5 ano, numero de alunos com proficiencia nos dois, numero de alunos que pularam duas series
					if `amostra' == 0 & `sub' == 1 {				//total de alunos (se amostra = 1, so pega aqueles ques estao em escolas que oferecem o acelera)
					
					  preserve
						use 		`mat' if year >= 2010 & type_program == 3, clear							//vamos ver o tamanho da amostra e a % de alunos com resultados no exame de proficiencia
						collapse (sum) pulou2_program3, by(year)
						tempfile	pulou2
						save 	   `pulou2'
					  restore
					  
					  preserve
						use 		`mat' if year >= 2010, clear												//vamos ver o tamanho da amostra e a % de alunos com resultados no exame de proficiencia
						gen id = 1
						collapse (sum)id (mean)tem_prof3ano tem_prof5ano tem_prof3e5ano, by(year  acelera_school  type_program)
						reshape  wide id* tem_prof*,  i(year type_program) j(acelera_school)												
						reshape  wide id* tem_prof*,  i(year ) 			   j(type_program)													
						drop id03 tem_prof3e5ano03
						gen col1 = .
						gen col2 =.
						foreach var of varlist tem* {
						replace `var' = `var'*100
						}
						merge 1:1 year using `pulou2'
						replace  pulou2_program3 =  pulou2_program3/id13
						order id01 tem_prof3ano01 tem_prof5ano01 tem_prof3e5ano01 col1 id13 pulou2_program3  tem_prof3ano13 tem_prof5ano13 tem_prof3e5ano13 col2  id11 tem_prof3ano11 tem_prof5ano11 tem_prof3e5ano11 
						keep  id01 tem_prof3ano01 tem_prof5ano01 tem_prof3e5ano01 col1 id13 pulou2_program3  tem_prof3ano13 tem_prof5ano13 tem_prof3e5ano13 col2  id11 tem_prof3ano11 tem_prof5ano11 tem_prof3e5ano11
						br id01 					tem_prof3ano01 tem_prof5ano01 tem_prof3e5ano01 col1 ///							//TABELA
						   id13 pulou2_program3   	tem_prof3ano13 tem_prof5ano13 tem_prof3e5ano13 col2 ///
						   id11 					tem_prof3ano11 tem_prof5ano11 tem_prof3e5ano11 
						export excel using "$tables/teste.xlsx",  firstrow(variables) replace
					restore
					}
					
						
					**
					*----------------------------------->>
					*Agora vamos voltar a base de dados e selecionar apenas os alunos elegiveis ao acelera no 4 ano e que entraram no acelera no 4 ano. 
					use `data', clear
					
						**
						merge m:1 cd_mat using `mat', keep(3) nogen														//encontrando esses alunos na base de dados. 
							 
						**
						sort cd_mat year
						
						**
						br   cd_mat year grade acelera2018 prof_LP_stand ultima_vez_3ano primeira_vez_5ano

						*Alunos no 4o ano 4o ano que podem ser incluidos na analise
						*----------------------------------->>
						**
						{
						preserve 
							keep 				if grade == 4
							tempfile 						4ano														//alunos da nossa analise quando matriculados no 4o ano. 
							save    			   		   `4ano'
						restore
						}
						
						
						*Selecao de apenas aqueles que apresentam notas no 3o e no 5 ano. 
						*----------------------------------->>
						**
						{
						keep if year == ultima_vez_3ano | year == primeira_vez_5ano 									//mantendo a proficiencia desses alunos no 3o ano e no 5o ano
						sort 	cd_mat year 
						br 		cd_mat year grade ultima_vez_3ano  primeira_vez_5ano 	
						bys 			cd_mat: gen  t = _N			
						keep 					  if t == 2   															//so os que fizeram teste nos dois anos
						}
						
						
						*Balance test
						*----------------------------------->>
						{
							global balance_test distorcao prof_LP prof_MT approved gender dif_idade_turma
							iebaltab $balance_test if grade == 3, grpvar(acelera2018) format(%12.2fc) fixedeffect(year)   save("$tables/balance-fourth-grade.xls") rowvarlabels replace 
							}
						
						
						**
						*No matching
						*----------------------------------->>
						{
						xtset cd_mat year
						
						*replace distorcao 		     = distorcao4ano if grade == 5
						*replace students_class      = students_class4ano if grade == 5
						*gen 	d_acelera_distorcao  = d_acelera*gender
						*gen 	d_aceleraseliga      = ja_participou_seliga == 1 & grade == 5		//nao afeta
						
						eststo test`amostra'`sub':  xtreg `subject' d_acelera i.codschool i.year i.grade i.gender students_class dif_idade_turma distorcao, fe
						if `sub' == 1  treated_control, test(`amostra'`sub') outcome(prof_LP)
						if `sub' == 2  treated_control, test(`amostra'`sub') outcome(prof_MT)
						if `sub' == 3 | `sub' == 4  treated_control, test(`amostra'`sub') outcome(`subject')
						}
						
						
						**
						*PSM
						*----------------------------------->>
						{
						preserve
							duplicates drop cd_mat, force
							keep 			cd_mat acelera2018 acelera_school
							tempfile		 mat
							save   		    `mat'
						restore

						preserve
							use 	`4ano', clear
							merge 	 m:1 cd_mat using `mat', keep(3) nogen 
								
											psmatch2 acelera2018 distorcao ja_participou_seliga i.status_anterior i.codschool i.year gender dif_idade_turma, n(3) common ties
										
												tw kdensity _pscore if acelera2018 == 0  [aw = _weight],  lw(1.5) lp(dash) color(red) 				///
												///
												|| kdensity _pscore if acelera2018 == 1  [aw = _weight],  lw(thick) lp(dash) color(gs12) 			///
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
				
						**
						merge m:1 cd_mat using `sample', keep(3) 
							
						eststo test`amostra'`sub'mat: xtreg `subject' d_acelera i.codschool i.year i.grade i.gender students_class dif_idade_turma distorcao, fe
						if `sub' == 1  treated_control, test(`amostra'`sub'mat) outcome(prof_LP)
						if `sub' == 2  treated_control, test(`amostra'`sub'mat) outcome(prof_MT)
						if `sub' == 3 | `sub' == 4  treated_control, test(`amostra'`sub'mat) outcome(`subject')
						}	
				}	
		}			
		

		
		
		estout * using "$tables/Table.xls",  keep(d_acelera*)  cells(b(star fmt(2)) se(par(`"="("' `")""') fmt(2))  ci(par)) starlevels(* 0.10 ** 0.05 *** 0.01) stats(N r2 space unique_treat outcome_treat sd_treat space unique_control outcome_control unique_school  , labels("Obs" "R2" "Treated Group" "Students" "Mean outcome" "SD" "ATT in sd" " Comparison Group" "Students" "Mean outcome"  "Num. schools") fmt(%9.0g %9.2f %9.2f)) replace
		estout test01 test11 test01mat test11mat  test02 test12 test02mat test11mat using "$tables/Table.xls",  keep(d_acelera*)  cells(b(star fmt(2)) se(par(`"="("' `")""') fmt(2))  ci(par)) starlevels(* 0.10 ** 0.05 *** 0.01) stats(N r2 space unique_treat outcome_treat sd_treat space unique_control outcome_control unique_school  , labels("Obs" "R2" "Treated Group" "Students" "Mean outcome" "SD" "ATT in sd" " Comparison Group" "Students" "Mean outcome"  "Num. schools") fmt(%9.0g %9.2f %9.2f)) replace
		
		
		
		

	
	
/*
	
	
	
	
	
		**
	*----------------------------------->>
	*Spillovers
	
	estimates clear 
	
	foreach sub in 	   1 2 {
	
	use 	"$dtfinal/SE LIGA & Acelera_Recife.dta", clear

	if `sub' == 1 local subject = "LP"
	if `sub' == 2 local subject = "MT"
	
	bys 		cd_mat: egen 	ultima_vez_3ano   = max(year) 	if grade == 3  & prof_`subject'_stand != .				//ultima   vez desse ano no 3o ano
	bys 		cd_mat: egen 	primeira_vez_5ano = min(year) 	if grade == 5  & prof_`subject'_stand != .				//primeira vez desse ano no 5o ano
	bys			cd_mat: egen 	tem_prof3ano 	  = max(ultima_vez_3ano  ) 
	bys 		cd_mat: egen 	tem_prof5ano 	  = max(primeira_vez_5ano)
	replace 	tem_prof3ano 	= 1 							if tem_prof3ano !=.
	replace 	tem_prof3ano 	= 0 							if tem_prof3ano ==.
	replace 	tem_prof5ano 	= 1	 							if tem_prof5ano !=.
	replace 	tem_prof5ano 	= 0 							if tem_prof5ano ==.
	
	gen 		tem_prof3e5ano = tem_prof3ano == 1 & tem_prof5ano == 1
	
	tempfile data
	save 	`data'
	
		foreach amostra in 0 1{
			
			**
			*----------------------------------->>
			*Regressions
			
			use `data', clear
				
				if `amostra' == 1 keep if acelera_school == 1

				**
				*----------------------------------->>
				*Alunos elegiveis ao Acelera no 4o ano. 
				
					preserve
						keep		 if none2018 == 1 & el1_4ano == 1 & grade == 4	& n_alunos_migraram_acelera == 0								//aqui sao os alunos que nunca participaram do se liga ou acelera e que eram elegiveis ao programa no 4 ano
						duplicates	 drop cd_mat, force

						gen				tratado = 0 if (n_alunosvaomigrar_acelera == 0) | year < 2010
						replace 		tratado = 1 if (n_alunosvaomigrar_acelera >  0) & year > 2009
						
						keep 			  	cd_mat year type_program codschool acelera_school tem_prof3ano tem_prof5ano tem_prof3e5ano grade tratado
						tempfile 			   mat
						save 				  `mat'		//amostra total
					restore
					
					
				**
				*----------------------------------->>
				*Agora vamos voltar a base de dados e selecionar apenas os alunos elegiveis ao acelera no 4 ano e que entraram no acelera no 4 ano. 
				
				use `data', clear
				
					**
					merge m:1 cd_mat using `mat', keep(3) nogen														//encontrando esses alunos na base de dados. 
		 
					**
					sort cd_mat year
					
					**
					br   cd_mat year grade prof_LP_stand ultima_vez_3ano primeira_vez_5ano tratado
			
					*Alunos do 4o ano que podem ser incluidos na analise
					*----------------------------------->>
					**
					preserve 
						keep 				if grade == 4
						tempfile 						4ano														//alunos da nossa analise quando matriculados no 4o ano. 
						save    			   		   `4ano'
					restore
					
					
					*Selecao de apenas aqueles que apresentam notas no 3o e no 5 ano. 
					*----------------------------------->>
					**
					keep if year == ultima_vez_3ano | year == primeira_vez_5ano 									//mantendo a proficiencia desses alunos no 3o ano e no 5o ano
					bys 			cd_mat: gen  t = _N			
					keep 					  if t == 2   															//so os que fizeram teste nos dois anos

					replace tratado = 0 if grade == 3 & tratado == 1
					
					
					**
					*------------------------>> Sem matching 
					xtset cd_mat year

					eststo test`amostra'`sub':  xtreg prof_`subject'_stand tratado i.codschool i.year i.grade i.gender students_class dif_idade_turma distorcao $schoolinfra, fe
					treated_control, test(`amostra'`sub') outcome(prof_`subject')
					
						
						**
						**Relacao de alunos com prof no 3o e no 5ano para o PSM
						preserve
						duplicates drop cd_mat, force
						keep 			cd_mat acelera2018 acelera_school
						tempfile		 mat
						save   		    `mat'
						restore
		
						**
						**Propensity score matching 
						preserve
							**
							use 	`4ano', clear
							merge 	 m:1 cd_mat using `mat', keep(3) nogen 
							
										psmatch2 tratado distorcao i.status_anterior i.codschool i.year gender dif_idade_turma, n(3) common ties
									
											tw kdensity _pscore if tratado == 0  [aw = _weight],  lw(1.5) lp(dash) color(red) 				///
											///
											|| kdensity _pscore if tratado == 1  [aw = _weight],  lw(thick) lp(dash) color(gs12) 			///
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
			
					
						merge m:1 cd_mat using `sample', keep(3) 
						
	
						eststo test`amostra'`sub'mat: xtreg prof_`subject'_stand tratado i.codschool i.year i.grade i.gender students_class dif_idade_turma distorcao $schoolinfra, fe
						treated_control, test(`amostra'`sub'mat) outcome(prof_`subject')
						
		

			}	
		}			
				
			estout * using "$tables/Table.xls",  keep(tratado)  cells(b(star fmt(2)) se(fmt(2))  ci(par)) starlevels(* 0.10 ** 0.05 *** 0.01) stats(N r2 space unique_treat outcome_treat sd_treat ATT_sd space unique_control outcome_control unique_school  , labels("Obs" "R2" "Treated Group" "Students" "Mean outcome" "SD" "ATT in sd" " Comparison Group" "Students" "Mean outcome"  "Num. schools") fmt(%9.0g %9.2f %9.2f)) replace

	
	
	
	
	
	
	
	
	
	
	
	