--
-- Copyright (c) 2015 Matthew Ragan
-- All rights reserved.
-- 
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
-- 
--      http://www.apache.org/licenses/LICENSE-2.0
-- 
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

DO $$
BEGIN
	PERFORM * FROM val_component_function WHERE component_function = 'memory';

	IF NOT FOUND THEN
		INSERT INTO val_component_function (component_function, description)
			VALUES ('memory', 'Memory');

		INSERT INTO val_component_property_type (
			component_property_type, description, is_multivalue
		) VALUES 
			('memory', 'memory properties', 'Y');

		--
		-- Insert a sampling of component function properties
		--
		INSERT INTO val_component_property (
			component_property_name,
			component_property_type,
			description,
			is_multivalue,
			property_data_type,
			required_component_function,
			permit_component_type_id
		) VALUES 
			('MemorySize', 'memory', 'Memory Size (MB)', 'N', 'number',
				'memory', 'REQUIRED'),
			('MemorySpeed', 'memory', 'Memory Speed (MHz)', 'N', 'number',
				'memory', 'REQUIRED');

		--
		-- Slot functions are also somewhat arbitrary, and exist for associating
		-- valid component_properties, for displaying UI components, and for
		-- validating inter_component_connection links
		--
		INSERT INTO val_slot_function (slot_function, description) VALUES
			('memory', 'Memory slot');

		--
		-- Slot types are not arbitrary.  In order for a component to attach to a
		-- slot, a specific linkage must exist in either
		-- slot_type_permitted_component_type for internal connections (i.e. the
		-- component becomes a logical sub-component of the parent) or in
		-- slot_type_prmt_rem_slot_type for an external connection (i.e.
		-- a connection to a separate component entirely, such as a network or
		-- power connection)
		--

		--
		-- Memory slots
		--

		INSERT INTO val_slot_physical_interface
			(slot_physical_interface_type, slot_function)
		SELECT
			unnest(ARRAY[
				'DDR3 RDIMM',
				'DDR4 DIMM'
			]),
			'memory'
		;


		INSERT INTO slot_type 
			(slot_type, slot_physical_interface_type, slot_function,
			 description, remote_slot_permitted)
		VALUES
			('DDR3 RDIMM', 'DDR3 RDIMM', 'memory', 'DDR3 RDIMM', 'N'),
			('DDR4 DIMM', 'DDR4 DIMM', 'memory', 'DDR4 DIMM', 'N');

		--
		-- Insert the permitted memory connections.  Memory can only go into a
		-- slot of the same type
		-- 

		INSERT INTO slot_type_prmt_comp_slot_type (
			slot_type_id,
			component_slot_type_id
		) SELECT
			st.slot_type_id,
			st.slot_type_id
		FROM
			slot_type st
		WHERE
			st.slot_function = 'memory';
	END IF;
END; $$ language plpgsql;
