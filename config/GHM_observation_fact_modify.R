library(data.table)
fact_tmp <- fact_tmp[,c("patient_num", "encounter_num", "instance_num",  "provider_id", "location_cd", "start_date", "end_date", "concept_cd", "tval_char", "sourcesystem_cd")]
setnames(fact_tmp,c("id_patient", "id_visite", "id_fait", "unite_executrice", "unite_responsabilite", "date_debut_visite", "date_fin_visite", "code_ghm", "code_ghs", "source" ))
file_name <- "fait_ghm"
