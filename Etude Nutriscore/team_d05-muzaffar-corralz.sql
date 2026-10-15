/*SAE2.04 Muzaffar Raaid, Corral Zacharie

Quel lien peut-on établir entre le nutriscore (A,B,C,D,E) et les variables nutritionnelles
pour les produits de la famille 'en:one-dish-meals' aux Etats-Unis ?

Extraction et nettoyage) */

CREATE TEMP TABLE extraction AS SELECT code, url, product_name,food_groups, labels_tags, countries,countries_tags,quantity,
fat_100g,saturated_fat_100g,sugars_100g,proteins_100g,carbohydrates_100g ,energy_100g,
salt_100g,sodium_100g,nutriscore_grade FROM openfoodfacts;

/* Nous avons créé une table temporaire sans altérer les lignes avec seulement les champs qui nous semblaient pertinents. */


DELETE FROM extraction WHERE countries_tags NOT LIKE '%united-states%' OR countries_tags IS NULL;
DELETE FROM extraction WHERE food_groups NOT LIKE '%en:one-dish-meals%' OR food_groups IS NULL;
DELETE FROM extraction WHERE code IS NULL OR code='';
DELETE FROM extraction WHERE nutriscore_grade=NULL OR nutriscore_grade='unknown' OR nutriscore_grade='not-applicable';

/* On enlève les lignes qui ne correspondent pas à notre sujet et celles qui ont un code et nutriscore_grade non-utilisable. */


DELETE FROM extraction WHERE code IN(SELECT o.code FROM openfoodfacts o WHERE data_quality_errors_tags IS NOT NULL);

/* On enlève les produits qui ont des erreurs. */


DELETE FROM extraction WHERE length(code) <> 13 OR code !~ '^[0-9]{13}$';

/* On enlève les codes qui ne font pas exactement 13 chiffres. */


DELETE FROM extraction WHERE fat_100g<0 OR saturated_fat_100g<0 OR sugars_100g<0 OR proteins_100g<0 OR carbohydrates_100g <0 OR salt_100g<0 OR sodium_100g<0;

DELETE FROM extraction WHERE fat_100g>100 OR saturated_fat_100g>100 OR sugars_100g>100 OR proteins_100g>100 OR carbohydrates_100g >100 OR salt_100g>100 OR sodium_100g>100;

DELETE FROM extraction WHERE saturated_fat_100g>fat_100g OR sugars_100g>carbohydrates_100g;

DELETE FROM extraction WHERE fat_100g+carbohydrates_100g+proteins_100g+salt_100g>100;

/* On enlève les lignes qui comportent des valeurs nutritionnelles impossibles. */


ALTER TABLE extraction ADD computed_energy_100g numeric;

UPDATE extraction SET computed_energy_100g=(proteins_100g*17)+(fat_100g*37)+(carbohydrates_100g*17);

/* On ajoute un champ où l'on calcul l'énergie d'un aliment avec les valeurs nutritionnelles données pour voir si cela se rapproche de l'énergie donnée. */


ALTER TABLE extraction ADD organic varchar;
UPDATE extraction SET organic = CASE WHEN labels_tags LIKE '%organic%' OR labels_tags LIKE '%biologique%' THEN TRUE
WHEN  labels_tags IS NULL OR labels_tags='' THEN NULL
ELSE FALSE
END;

/* On a ajouté un champ pour savoir si les aliments sont bio ou non. */


ALTER TABLE extraction ADD vegan boolean;
ALTER TABLE extraction ADD vegetarian boolean;
ALTER TABLE extraction ADD palm_oil boolean;

UPDATE extraction e SET vegan = CASE WHEN o.ingredients_analysis_tags LIKE '%en:vegan%' THEN TRUE
            WHEN o.ingredients_analysis_tags LIKE '%en:non-vegan%' THEN FALSE
            ELSE NULL
       END
FROM openfoodfacts o
WHERE o.code=e.code;

UPDATE extraction e SET vegan = CASE WHEN o.ingredients_analysis_tags LIKE '%en:vegetarian%' THEN TRUE
            WHEN o.ingredients_analysis_tags LIKE '%en:non-vegetarian%' THEN FALSE
            ELSE NULL
       END
FROM openfoodfacts o
WHERE o.code=e.code;

UPDATE extraction e SET vegan = CASE WHEN o.ingredients_analysis_tags LIKE '%en:palm-oil%' THEN TRUE
            WHEN o.ingredients_analysis_tags LIKE '%en:palm-oil-free%' THEN FALSE
            ELSE NULL
       END
FROM openfoodfacts o
WHERE o.code=e.code;

/* On ajoute 3 champs pour savoir s'ils sont compatibles avec un régime vegan, végétarien ou s'ils contiennent de l'huile de palme puis on remplit ces champs. */


ALTER TABLE extraction ADD level_fat varchar;
ALTER TABLE extraction ADD level_saturated_fat varchar;
ALTER TABLE extraction ADD level_sugars varchar;
ALTER TABLE extraction ADD level_salt varchar;

UPDATE extraction e SET level_fat = CASE WHEN o.nutrient_levels_tags LIKE '%en:fat-in-high-quantity%' THEN 'h'
            WHEN o.nutrient_levels_tags LIKE '%en:fat-in-moderate-quantity%' THEN 'm'
            WHEN o.nutrient_levels_tags LIKE '%en:fat-in-low-quantity%' THEN 'l'
            ELSE NULL
       END
FROM openfoodfacts o
WHERE o.code=e.code;

UPDATE extraction e SET level_saturated_fat= CASE WHEN o.nutrient_levels_tags LIKE '%en:saturated-fat-in-high-quantity%' THEN 'h'
            WHEN o.nutrient_levels_tags LIKE '%en:saturated-fat-in-moderate-quantity%' THEN 'm'
            WHEN o.nutrient_levels_tags LIKE '%en:saturated-fat-in-low-quantity%' THEN 'l'
            ELSE NULL
       END
FROM openfoodfacts o
WHERE o.code=e.code;

UPDATE extraction e SET level_sugars = CASE WHEN o.nutrient_levels_tags LIKE '%en:sugars-in-high-quantity%' THEN 'h'
            WHEN o.nutrient_levels_tags LIKE '%en:sugars-in-moderate-quantity%' THEN 'm'
            WHEN o.nutrient_levels_tags LIKE '%en:sugars-in-low-quantity%' THEN 'l'
            ELSE NULL
       END
FROM openfoodfacts o
WHERE o.code=e.code;

UPDATE extraction e SET level_salt = CASE WHEN o.nutrient_levels_tags LIKE '%en:salt-in-high-quantity%' THEN 'h'
            WHEN o.nutrient_levels_tags LIKE '%en:salt-in-moderate-quantity%' THEN 'm'
            WHEN o.nutrient_levels_tags LIKE '%en:salt-in-low-quantity%' THEN 'l'
            ELSE NULL
       END
FROM openfoodfacts o
WHERE o.code=e.code;

/* On ajoute 4 champs pour indiquer la quantité de graisse et autres contenue dans les aliments puis on les remplit. */


DELETE FROM extraction
WHERE code IN (
    SELECT code
    FROM extraction
    GROUP BY code
    HAVING COUNT(DISTINCT product_name) > 1
       OR COUNT(DISTINCT fat_100g) > 1);

DELETE FROM extraction
WHERE ctid NOT IN (
    SELECT MIN(ctid)
    FROM extraction
    GROUP BY code);


/* On supprime les doublons. */























