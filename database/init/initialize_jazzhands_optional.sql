-- Copyright (c) 2005-2010, Vonage Holdings Corp.
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
--     * Redistributions of source code must retain the above copyright
--       notice, this list of conditions and the following disclaimer.
--     * Redistributions in binary form must reproduce the above copyright
--       notice, this list of conditions and the following disclaimer in the
--       documentation and/or other materials provided with the distribution.
--
-- THIS SOFTWARE IS PROVIDED BY VONAGE HOLDINGS CORP. ''AS IS'' AND ANY
-- EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL VONAGE HOLDINGS CORP. BE LIABLE FOR ANY
-- DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
-- ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

-- 
-- $Id$
--
-- Items that are accurate but are not strictly required

insert into  val_snmp_commstr_type (SNMP_COMMSTR_TYPE, DESCRIPTION)
	values ('Legacy', 'Used by Legacy Apps'); 
insert into  val_snmp_commstr_type (SNMP_COMMSTR_TYPE, DESCRIPTION)
	values ('Cricket', 'Used by the Cricket Application'); 

INSERT INTO Partner (Partner_ID, Name)
	VALUES (0, 'Not Applicable');
UPDATE Partner SET Partner_ID = 0 where Name = 'Not Applicable';
INSERT INTO Partner (Name)
	VALUES ('Sun Microsystems');
INSERT INTO Partner (Name)
	VALUES ('IBM');
INSERT INTO Partner (Name)
	VALUES ('RedHat');
INSERT INTO Partner (Name)
	VALUES ('Debian');
INSERT INTO Partner (Name)
	VALUES ('HP');
INSERT INTO Partner (Name)
	VALUES ('Cyclades');
INSERT INTO Partner (Name)
	VALUES ('Xen');

INSERT INTO Device_Type (
	Partner_ID,
	Model,
	Has_802_3_Interface,
	Has_802_11_Interface,
	SNMP_Capable,
	is_chasis,
	rack_units
) VALUES (
	0,
	'unknown',
	'N',
	'N',
	'N',
	'N',
	0
);

INSERT INTO Device_Type (
	Partner_ID,
	Model,
	Has_802_3_Interface,
	Has_802_11_Interface,
	SNMP_Capable,
	Is_Chasis,
	RACK_UNITS
) VALUES (
	(SELECT Partner_ID FROM Partner WHERE Name = 'Sun Microsystems'),
	'SunFire T1000',
	'Y',
	'N',
	'Y',
	'Y',
	1
);

INSERT INTO Device_Type (
	Partner_ID,
	Model,
	Has_802_3_Interface,
	Has_802_11_Interface,
	SNMP_Capable,
	Is_Chasis,
	RACK_UNITS
) VALUES (
	(SELECT Partner_ID FROM Partner WHERE Name = 'Sun Microsystems'),
	'SunFire T2000',
	'Y',
	'N',
	'Y',
	'Y',
	1
);

INSERT INTO Device_Type (
	Partner_ID,
	Model,
	Has_802_3_Interface,
	Has_802_11_Interface,
	SNMP_Capable, is_chasis, rack_units
) VALUES (
	(SELECT Partner_ID FROM Partner WHERE Name = 'IBM'),
	'eServer 326',
	'Y',
	'N',
	'Y', 'Y', 2
);

INSERT INTO Device_Type (
	Partner_ID,
	Model,
	Has_802_3_Interface,
	Has_802_11_Interface,
	SNMP_Capable, is_chasis, rack_units
) VALUES (
	(SELECT Partner_ID FROM Partner WHERE Name = 'HP'),
	'DL360',
	'Y',
	'N',
	'Y', 'Y', 1
);

INSERT INTO Device_Type (
	Partner_ID,
	Model,
	Has_802_3_Interface,
	Has_802_11_Interface,
	SNMP_Capable,
	Is_Chasis,
	Rack_Units
) VALUES (
	(SELECT Partner_ID FROM Partner WHERE Name = 'Cyclades'),
	'AlterPath ACS48',
	'Y',
	'N',
	'Y',
	'Y',
	1
);

INSERT INTO Device_Type (
	Partner_ID,
	Model,
	Has_802_3_Interface,
	Has_802_11_Interface,
	SNMP_Capable,
	Is_Chasis,
	Rack_Units
) VALUES (
	(SELECT Partner_ID FROM Partner WHERE Name = 'Xen'),
	'Virtual Machine',
	'Y',
	'N',
	'Y',
	'Y',
	0
);

INSERT INTO Operating_System (
	Operating_System_ID,
	Name,
	Version,
	Partner_ID, processor_architecture
) VALUES (
	0,
	'unknown',
	'unknown',
	0, 'noarch'
);
UPDATE Operating_System SET Operating_System_ID = 0 where Partner_ID = 0;

INSERT INTO Operating_System (
	Name,
	Version,
	Partner_ID,
	PROCESSOR_ARCHITECTURE
) VALUES(
	'Solaris',
	'10',
	(SELECT Partner_ID FROM Partner WHERE Name = 'Sun Microsystems'),
	'amd64'
);

INSERT INTO Operating_System (
	Name,
	Version,
	Partner_ID,
	PROCESSOR_ARCHITECTURE
) VALUES(
	'Solaris',
	'10',
	(SELECT Partner_ID FROM Partner WHERE Name = 'Sun Microsystems'),
	'sparc'
);
