CREATE OR REPLACE VIEW `view_ra_candidate` AS
(
SELECT i.id as identity_id, i.institution, i.common_name, i.email, i.name_id, a.institution AS ra_institution
FROM vetted_second_factor vsf
         INNER JOIN identity i on vsf.identity_id = i.id
         INNER JOIN institution_authorization a
                    ON (a.institution_role = 'select_raa' AND a.institution_relation = i.institution)
WHERE NOT EXISTS(SELECT NULL FROM ra_listing AS l WHERE l.identity_id = i.id AND l.ra_institution = a.institution)
    );