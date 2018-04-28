library(data.table)
fact_tmp <- fact_tmp[,c("patient_num", "encounter_num", "instance_num", "provider_id", "location_cd", "start_date", "concept_cd","sourcesystem_cd")]
fact_tmp <- data.table(fact_tmp)
setnames(fact_tmp,c( "id_patient", "id_visite", "id_fait", "unite_executrice", "unite_responsabilite", "date_codage", "code_ccam","source"))
file_name <- "fait_act"
