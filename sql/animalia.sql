select s.name_element, tne.taxon_id, t.taxonomic_rank_id, t.id, tr.rank
from scientific_name_element s, taxon_name_element tne, taxon t, taxonomic_rank tr
where s.id = tne.scientific_name_element_id and tne.parent_id = 22032961
and t.id = tne.taxon_id and tr.id = t.taxonomic_rank_id;