/*-------------------------------------------------------------------------
 *
 * pg_tag_description.h
 *	  definition of the "tag description" system catalog (pg_tag_description)
 *
 *
 * Portions Copyright (c) 2024, Hashdata Inc.
 *
 * src/include/catalog/pg_tag_description.h
 *
 * NOTES
 *	  The Catalog.pm module reads this file and derives schema
 *	  information.
 *
 *-------------------------------------------------------------------------
 */

#ifndef PG_TAG_DESCRIPTION_H
#define PG_TAG_DESCRIPTION_H

#include "catalog/genbki.h"
#include "catalog/pg_tag_description_d.h"
#include "parser/parse_node.h"

/* ----------------
 *		pg_tag_description definition.    cpp turns this into
 *		typedef struct FormData_pg_tag_description
 * ----------------
 */
CATALOG(pg_tag_description,6485,TagDescriptionRelationId) BKI_SHARED_RELATION BKI_ROWTYPE_OID(6486,TagDescriptionRelation_Rowtype_Id) BKI_SCHEMA_MACRO
{
	Oid			oid		BKI_FORCE_NOT_NULL;				/* OID of this tag description */
	Oid			tddatabaseid	BKI_LOOKUP_OPT(pg_database);	/* OID of database containing object */
	Oid			tdclassid	BKI_LOOKUP_OPT(pg_class);		/* OID of table containing object */
	Oid 		tdobjid;			/* OID of object itself */
	Oid 		tagid	BKI_LOOKUP_OPT(pg_tag);			/* Oid of tag */
#ifdef CATALOG_VARLEN			/* variable-length fields start here */
	text		tagvalue;		/* tag value for this object */
#endif
} FormData_pg_tag_description;

/* ----------------
 *		Form_pg_tag_description corresponds to a pointer to a tuple with
 *		the format of pg_tag_description relation.
 * ----------------
 */
typedef FormData_pg_tag_description *Form_pg_tag_description;

DECLARE_UNIQUE_INDEX_PKEY(pg_tag_description_d_c_o_t_index, 6487, on pg_tag_description using btree(tddatabaseid oid_ops, tdclassid oid_ops, tdobjid oid_ops, tagid oid_ops));
#define TagDescriptionIndexId	6487
DECLARE_UNIQUE_INDEX(pg_tag_description_oid_index, 6488, on pg_tag_description using btree(oid oid_ops));
#define TagDescriptionOidIndexId	6488
DECLARE_INDEX(pg_tag_description_tagidvalue_index, 6489, on pg_tag_description using btree(tagid oid_ops, tagvalue text_ops));
#define TagDescriptionTagidvalueIndexId	6489

#endif							/* PG_TAG_DESCRIPTION_H */