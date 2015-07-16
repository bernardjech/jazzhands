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
	PERFORM * FROM company WHERE company_name = 'Dell';
	IF NOT FOUND THEN
		INSERT INTO company (company_name) VALUEs ('Dell');
	END IF;
END; $$ language plpgsql;

\ir Dell_PowerEdge_C6100.sql
\ir Dell_PowerEdge_C6220.sql
\ir Dell_PowerEdge_R720.sql
\ir Dell_PowerEdge_R730.sql
\ir Dell_PowerEdge_R630.sql
\ir Dell_FX2.sql
