with Ada.Text_IO; use Ada.Text_IO;
with Interfaces;
with Ada.Containers.Generic_Array_Sort;

procedure Main is
	type U64 is new Interfaces.Unsigned_64;

	function Find_Next_Space(Line: String; N: Natural) return Natural is
	begin
		for I in N..Line'Last loop
			if Line(I) = ' ' then
				return I;
			end if;
		end loop;
		pragma Assert(false, "Unreachable");
		return 0;
	end Find_Next_Space;

	function Find_First_Space(Line: String) return Natural is
	begin
		return Find_Next_Space(Line, Line'First);
	end Find_First_Space;

	function Find_Last_Eq(Line: String) return Natural is
	begin
		for I in reverse Line'Range loop
			if Line(I) = '=' then
				return I;
			end if;
		end loop;
		pragma Assert(false, "Unreachable");
		return 0;
	end Find_Last_Eq;

	function Find_Eq_N(Line: String; N: Natural) return Natural is
		Count: Natural := 0;
	begin
		for I in Line'Range loop
			if Line(I) = '=' then
				Count := Count + 1;
				if Count = N then
					return I;
				end if;
			end if;
		end loop;
		pragma Assert(false, "Unreachable");
		return 0;
	end Find_Eq_N;
		
	function Read_ID(Line: String) return Natural is
		First_Space: Natural := Find_First_Space(Line);
		N: Natural := Natural'Value(Line(Line'First+3..First_Space-1));
	begin
		return N;
	end Read_ID;

	function Read_Time(Line: String) return U64 is
		Last_Eq: Natural := Find_Last_Eq(Line);
		N: U64 := U64'Value(Line(Last_Eq+1..Line'Last));
	begin
		return N;
	end Read_Time;

	function Read_Quest(Line: String) return Natural is
		Eq: Natural := Find_Eq_N(Line, 2);
		Space: Natural := Find_Next_Space(Line, Eq);
		N: Natural := Natural'value(Line(Eq+1..Space-1));
	begin
		return N;
	end Read_Quest;

	function Read_Part(Line: String) return Natural is
		Eq: Natural := Find_Eq_N(Line, 3);
		Space: Natural := Find_Next_Space(Line, Eq);
		N: Natural := Natural'value(Line(Eq+1..Space-1));
	begin
		return N;
	end Read_Part;

	function Count_Lines(Filename: String) return Natural is
		Result: Natural := 0;
		File: File_Type;
	begin
		Open(File, In_File, Filename);
		while not End_Of_File(File) loop
			declare
				Dummy_Line: constant String := Get_Line(File);
			begin
				Result := Result + 1;
			end;
		end loop;
		Close(File);
		return Result;
	end Count_Lines;

	function Find_Max_ID(Filename: String) return Natural is
		Result: Natural := 0;
		File: File_Type;
	begin
		Open(File, In_File, Filename);
		while not End_Of_File(File) loop
			declare
				Line: constant String := Get_Line(File);
				N: Natural := Read_ID(Line);
			begin
				if N > Result then
					Result := N;
				end if;
			end;
		end loop;
		Close(File);
		return Result;
	end Find_Max_ID;

	function Part_One(Filename: String) return U64 is
		Ans: U64 := 0;
		File: File_Type;
		Max_ID: Natural := Find_Max_ID(Filename);

		type Times_Array is array (Natural range <>) of U64;
		procedure Sort is new Ada.Containers.Generic_Array_Sort (
			Index_Type => Natural, Element_Type => U64, Array_Type => Times_Array	
		);
		Times: Times_Array(1..Max_ID) := ( others => 0 );
	begin
		Open(File, In_File, Filename);
		while not End_Of_File(File) loop
			declare
				Line: constant String := Get_Line(File);
				ID: Natural := Read_ID(Line);
				Time: U64 := Read_Time(Line);
			begin
				Times(ID) := Times(ID) + Time;
			end;
		end loop;
		Close(File);

		Sort(Times);
		for I in Times'Range loop
			Ans := Ans + U64(I) * Times(I);
		end loop;
		return Ans;
	end Part_One;

	function Part_Two(Filename: String) return U64 is
		Ans: U64 := 0;
		File: File_Type;
		Max_ID: Natural := Find_Max_ID(Filename);

		type Participant is record
			Time: U64;
			Parts: U64;
		end record;

		function Participant_Less(A: Participant; B: Participant) return Boolean is
		begin
			if A.Parts > B.Parts then
				return true;
			elsif A.Parts < B.Parts then
				return false;
			elsif A.Time < B.Time then
				return true;
			else
				return false;
			end if;
		end Participant_Less;

		type Participants_Array is array (Natural range <>) of Participant;
		procedure Sort is new Ada.Containers.Generic_Array_Sort (
			Index_Type => Natural,
			Element_Type => Participant,
			Array_Type => Participants_Array, 
			"<" => Participant_Less	
		);
		Participants: Participants_Array(1..Max_ID) := ( others => (0,0) );
	begin
		Open(File, In_File, Filename);
		while not End_Of_File(File) loop
			declare
				Line: constant String := Get_Line(File);
				ID: Natural := Read_ID(Line);
				Time: U64 := Read_Time(Line);
			begin
				Participants(ID).Time := Participants(ID).Time + Time;
				Participants(ID).Parts := Participants(ID).Parts + 1;
			end;
		end loop;
		Close(File);

		Sort(Participants);
		for I in Participants'Range loop
			Ans := Ans + U64(I) * Participants(I).Time;
		end loop;
		return Ans;
	end Part_Two;

	function Part_Three(Filename: String) return U64 is
		Ans: U64 := 0;
		File: File_Type;
		Max_ID: Natural := Find_Max_ID(Filename);
		Line_Count: Natural := Count_Lines(Filename);

		type Result is record
			ID: Natural;
			Quest: Natural;
			Part: Natural;
			Time: U64;
		end record;

		--Sort by Quest, then by Part, then by Time
		function Result_Less(A: Result; B: Result) return Boolean is
		begin
			if A.Quest < B.Quest then
				return true;
			elsif A.Quest > B.Quest then
				return false;

			elsif A.Part < B.Part then
				return true;
			elsif A.Part > B.Part then
				return false;

			else
				return A.Time < B.Time;
			end if;
		end;

		type Results_Array is array (Natural range <>) of Result;
		procedure Sort_Results is new Ada.Containers.Generic_Array_Sort (
			Index_Type => Natural,
			Element_Type => Result,
			Array_Type => Results_Array,
			"<" => Result_Less
		);

		function Score_Greater(A: U64; B: U64) return Boolean is
		begin
			return A > B;
		end;
		
		type Scores_Array is array (Natural range <>) of U64;
		procedure Sort_Scores is new Ada.Containers.Generic_Array_Sort (
			Index_Type => Natural,
			Element_Type => U64,
			Array_Type => Scores_Array,
			"<" => Score_Greater --Sort scores largest to smallest 
		);
		
		Results: Results_Array(1..Line_Count) := ( others => (0,0,0,0) );
		Scores: Scores_Array(1..Max_ID) := ( others => 0 );
	begin
		Open(File, In_File, Filename);

		-- Parse input
		for I in Results'Range loop
			declare
				Line: constant String := Get_Line(File);
			begin
				Results(I).ID    := Read_ID(Line);
				Results(I).Quest := Read_Quest(Line);
				Results(I).Part  := Read_Part(Line);
				Results(I).Time  := Read_Time(Line);
			end;
		end loop;
		pragma Assert(End_Of_File(File));
		Close(File);
		Sort_Results(Results);

		-- Assign points
		declare
			Index: Natural := Results'First;
			Prev_Index: Natural;
			Score: U64;
			Times: array(1..Max_ID) of U64 := ( others => 0 );

			-- Tie handling
			Prev_Score: U64 := 0;
			Prev_Time: U64 := 0;
		begin
			while Index <= Results'Last loop
				for Part in 1..3 loop
					-- Assign scores for the current part
					Score := U64(Part) * 50;
					while Index <= Results'Last and then Results(Index).Part = Part loop
						if Results(Index).Time = Prev_Time then
							Scores(Results(Index).ID) := Scores(Results(Index).ID) + Prev_Score;
						else
							Prev_Score := Score;
							Prev_Time := Results(Index).Time;
							Scores(Results(Index).ID) := Scores(Results(Index).ID) + Score;
						end if;
						Times(Results(Index).ID) := Results(Index).Time;
						
						if Score > 0 then
							Score := Score - 1;
						end if;
						Index := Index + 1;
					end loop;
					Prev_Index := Index;

					-- Exit this loop when there is no next part
					if Index > Results'Last or else Results(Index).Part /= Part+1 then
						exit;
					end if;
					
					-- Add times from the past part into the next
					while Index <= Results'Last and then Results(Index).Part = Part+1 loop
						Results(Index).Time := Results(Index).Time + Times(Results(Index).ID);
						Index := Index + 1;
					end loop;

					-- Sort the results for just the next part with the new times
					Sort_Results(Results(Prev_Index..Index-1));

					-- Set the Index back to the beginning of the next part for the next pass
					Index := Prev_Index;
					Prev_Score := 0;
					Prev_Time := 0;
				end loop;
			end loop;
		end;

		-- Sort by score and compute the answer
		Sort_Scores(Scores);
		declare
			Prev_Score: U64 := 0;
			Prev_I: Natural := 0;
		begin
			for I in Scores'Range loop
				if Scores(I) = Prev_Score then
					Ans := Ans + U64(Prev_I) * Prev_Score;
				else
					Ans := Ans + U64(I) * Scores(I);
					Prev_Score := Scores(I);
					Prev_I := I;
				end if;
			end loop;
		end;
		return Ans;
	end Part_Three;

begin
	declare
		X: U64 := Part_One("test1.txt");
	begin
		pragma Assert(X = 27598, "got" & X'Image);
	end;
	Put_Line("Part 1: " & Part_One("everybody_codes_e2026_q04_p1.txt")'Image);
	
	declare
		X: U64 := Part_Two("test2.txt");
	begin
		pragma Assert(X = 6470, "got" & X'Image);
	end;
	Put_Line("Part 2: " & Part_Two("everybody_codes_e2026_q04_p2.txt")'Image);

	declare
		X_1: U64 := Part_Three("test3_1.txt");
		X_2: U64 := Part_Three("test3_2.txt");
		X_3: U64 := Part_Three("test3_3.txt");
	begin
		pragma Assert(X_1 = 2998, "X_1 got" & X_1'Image);
		pragma Assert(X_2 = 3004, "X_2 got" & X_2'Image);
		pragma Assert(X_3 = 6232480, "X_3 got" & X_3'Image);
	end;
	Put_Line("Part 3: " & Part_Three("everybody_codes_e2026_q04_p3.txt")'Image);
end Main;
