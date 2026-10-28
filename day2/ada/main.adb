with Ada.Text_IO; use Ada.Text_IO;
with Ada.Containers.Vectors;
with Ada.Containers.Doubly_Linked_Lists;
with Interfaces;

procedure Main is
	type U64 is new Interfaces.Unsigned_64;

	generic
		Num_Blades: Natural;
	package Blades is
		subtype Blade is Natural range 1..Num_Blades;

		type Note is record
			Lesser: Blade;
			Greater: Blade;
		end record;

		package Note_Vectors is new Ada.Containers.Vectors (
			Index_Type => Natural, Element_Type => Note	
		);
		subtype Vec is Note_Vectors.Vector;

		package Blade_Lists is new Ada.Containers.Doubly_Linked_Lists (
			Element_Type => Blade
		);
		subtype List is Blade_Lists.List;

		function Char_To_Blade(C: Character) return Blade;
		function Parse_Line(File: File_Type) return Vec;
		function Process_Complete_Notes(Notes: Vec) return Natural;
		function Process_Notes_Missing_One(Notes: Vec) return Natural;
		function Process_Incomplete_Notes(Notes: Vec) return Natural;
	end Blades;

	package body Blades is
		function Char_To_Blade(C: Character) return Blade is
		begin
			return Blade(Character'Pos(C) - Character'Pos('0'));
		end Char_To_Blade;

		function Parse_Line(File: File_Type) return Vec is
			Result: Vec;
			Line: constant String := Get_Line(File);
			N: Note;
		begin
			for I in Line'Range loop
				if Line(I) = '<' then
					N.Lesser := Char_To_Blade(Line(I-1));
					N.Greater := Char_To_Blade(Line(I+1));
					Result.Append(N);
				elsif Line(I) = '>' then
					N.Lesser := Char_To_Blade(Line(I+1));
					N.Greater := Char_To_Blade(Line(I-1));
					Result.Append(N);
				end if;
			end loop;
			return Result;
		end Parse_Line;

		function Process_Complete_Notes(Notes: Vec) return Natural is
			Lesser_Counts: array(Blade) of Natural := ( others => 0 );
			Result: Natural := 0;
		begin
			for Element of Notes loop
				Lesser_Counts(Element.Lesser) := Lesser_Counts(Element.Lesser) + 1;
			end loop;

			for I in Blade'Range loop
				Result := Result * 10;
				for J in Blade'Range loop
					if Lesser_Counts(J) = I-1 then
						Result := Result + J;
						exit;
					end if;
				end loop;
			end loop;
			return Result;
		end;

		function Process_Notes_Missing_One(Notes: Vec) return Natural is
			Lesser_Counts: array(Blade) of Natural := ( others => 0 );
			Greater_Counts: array(Blade) of Natural := ( others => 0 );
			Result: Natural := 0;
		begin
			for Element of Notes loop
				Lesser_Counts(Element.Lesser) := Lesser_Counts(Element.Lesser) + 1;
				Greater_Counts(Element.Greater) := Greater_Counts(Element.Greater) + 1;
			end loop;

			-- Figure out which note is missing and correct it
			for I in Blade'Range loop
				if Lesser_Counts(I) + Greater_Counts(I) /= Blade'Last-1 then
					if Lesser_Counts(I) > Greater_Counts(I) then
						Lesser_Counts(I) := Lesser_Counts(I) + 1;
					else
						Greater_Counts(I) := Greater_Counts(I) + 1;
					end if;	
				end if;
			end loop;

			-- Same loop as in Process_Complete_Notes
			for I in Blade'Range loop
				Result := Result * 10;
				for J in Blade'Range loop
					if Lesser_Counts(J) = I-1 then
						Result := Result + J;
						exit;
					end if;
				end loop;
			end loop;
			return Result;
		end;

		function Process_Incomplete_Notes(Notes: Vec) return Natural is
			Lesser_Counts: array(Blade) of Natural := ( others => 0 );
			Greater_Counts: array(Blade) of Natural := ( others => 0 );
			Placed: array(Blade) of Boolean := ( others => false );
			Left_List: List;
			Right_List: List;
			Result: Natural := 0;

			-- Helper function that removes notes about placed blades from play
			procedure Update_Counts(B: Blade) is
			begin
				for Element of Notes loop
					if B = Element.Lesser and not Placed(Element.Greater) then
						Greater_Counts(Element.Greater) := Greater_Counts(Element.Greater) - 1;
					elsif B = Element.Greater and not Placed(Element.Lesser) then
						Lesser_Counts(Element.Lesser) := Lesser_Counts(Element.Lesser) - 1;
					end if;
				end loop;
			end Update_Counts;
		begin
			for Element of Notes loop
				Lesser_Counts(Element.Lesser) := Lesser_Counts(Element.Lesser) + 1;
				Greater_Counts(Element.Greater) := Greater_Counts(Element.Greater) + 1;
			end loop;

			-- Elements with a Lesser_Count or Greater_Count of zero,
			-- belong at either extreme end of the list
			while Natural(Left_List.Length) + Natural(Right_List.Length) < Blade'Last loop
				for I in Blade'Range loop
					if Lesser_Counts(I) = 0 and not Placed(I) then
						Left_List.Append(I);
						Update_Counts(I);
						Placed(I) := true;
					elsif Greater_Counts(I) = 0 and not Placed(I) then
						Right_List.Prepend(I);
						Update_Counts(I);
						Placed(I) := true;
					end if;
				end loop;
			end loop;

			for Element of Left_List loop
				Result := 10*Result + Element;
			end loop;
			for Element of Right_List loop
				Result := 10*Result + Element;
			end loop;
			return Result;
		end;
	end Blades;

	function Part_One(Filename: String; Num_Blades: Natural) return U64 is
		package Blades_Instance is new Blades(Num_Blades);
		use Blades_Instance;
	
		File: File_Type;
		Result: U64 := 0;
	begin
		Open(File, In_File, Filename);
		while not End_Of_File(File) loop
			Result := Result + U64(Process_Complete_Notes(Parse_Line(File)));
		end loop;
		Close(File);
		return Result;
	end Part_One;

	function Part_Two(Filename: String; Num_Blades: Natural) return U64 is
		package Blades_Instance is new Blades(Num_Blades);
		use Blades_Instance;
	
		File: File_Type;
		Result: U64 := 0;	
	begin
		Open(File, In_File, Filename);
		while not End_Of_File(File) loop
			Result := Result + U64(Process_Notes_Missing_One(Parse_Line(File)));
		end loop;
		Close(File);
		return Result;
	end Part_Two;
	
	function Part_Three(Filename: String; Num_Blades: Natural) return U64 is
		package Blades_Instance is new Blades(Num_Blades);
		use Blades_Instance;
	
		File: File_Type;
		Result: U64 := 0;		
	begin
		Open(File, In_File, Filename);
		while not End_Of_File(File) loop
			Result := Result + U64(Process_Incomplete_Notes(Parse_Line(File)));
		end loop;
		Close(File);
		return Result;
	end Part_Three;

begin
	declare
		X: U64 := Part_One("test1.txt", 5);
	begin
		pragma Assert(X = 122157, "got" & X'Image);
	end;
	Put_Line("Part 1: " & Part_One("everybody_codes_e2026_q02_p1.txt", 5)'Image);
	
	declare
		X: U64 := Part_Two("test2.txt", 5);
	begin
		pragma Assert(X = 122157, "got" & X'Image);
	end;
	Put_Line("Part 2: " & Part_Two("everybody_codes_e2026_q02_p2.txt", 9)'Image);

	declare
		X: U64 := Part_Three("test3.txt", 5);
	begin
		pragma Assert(X = 122157, "got" & X'Image);
	end;
	Put_Line("Part 3: " & Part_Three("everybody_codes_e2026_q02_p3.txt", 9)'Image);
end Main;
