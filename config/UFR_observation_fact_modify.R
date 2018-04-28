library(data.table)
fact_tmp <- fact_tmp[,c("patient_num", "encounter_num", "instance_num",  "provider_id", "start_date", "end_date", "concept_cd", "nval_num", "sourcesystem_cd")]
setnames(fact_tmp,c("id_patient", "id_visite", "id_fait", "unite_executrice", "date_debut_passage", "date_fin_passage", "code_unite_responsabilite", "duree_passage_jour", "source" ))
file_name <- "fait_passage"
