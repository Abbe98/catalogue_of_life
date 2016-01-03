select s.name_element, tne.taxon_id, tr.rank
from scientific_name_element s, taxon_name_element tne, taxon t, taxonomic_rank tr
where s.id = tne.scientific_name_element_id and tne.parent_id = 22042910
and t.id = tne.taxon_id and tr.id = t.taxonomic_rank_id;