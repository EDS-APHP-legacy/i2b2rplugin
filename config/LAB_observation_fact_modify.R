library(data.table)
fact_tmp <- fact_tmp[,c("patient_num", "encounter_num", "instance_num", "provider_id", "location_cd", "start_date", "concept_cd", "valtype_cd", "tval_char","nval_num", "valueflag_cd", "units_cd", "quantity_num", "confidence_num", "observation_blob","sourcesystem_cd")]
fact_tmp$valeur_lab_num <- ifelse(fact_tmp$valtype_cd%chin%"N",fact_tmp$nval_num,NA)
fact_tmp$valeur_lab_text <- ifelse(fact_tmp$valtype_cd%chin%"T",fact_tmp$tval_char,NA)
fact_tmp$operateur_lab <- ifelse(fact_tmp$valtype_cd%chin%"N",fact_tmp$tval_char,NA)
fact_tmp <- fact_tmp[,c("patient_num", "encounter_num", "instance_num",  "provider_id","location_cd", "start_date", "concept_cd", "valtype_cd", "operateur_lab", "valeur_lab_num", "valeur_lab_text", "units_cd", "valueflag_cd", "quantity_num", "confidence_num", "observation_blob","sourcesystem_cd")]
setnames(fact_tmp,c("id_patient", "id_visite", "id_fait", "unite_executrice", "unite_responsabilite", "date_execution", "code_lab", "valeur_lab_type", "operateur_lab", "valeur_lab_num","valeur_lab_text", "unite_mesure", "valeur_ref_flag", "valeur_ref_inf", "valeur_ref_sup", "commentaire_lab","source"))
file_name <- "fait_lab"
