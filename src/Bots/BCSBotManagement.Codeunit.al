codeunit 88001 "BCS Bot Management"
{

    procedure PurchaseBot(var ResCheckBuffer: Record "BCS Resource Check Buffer"; WhichTemplate: Code[20]): Text[20]
    var
        Template: Record "BCS Bot Template";
        Instance: Record "BCS Bot Instance";
        BCSPlayerCharge: Codeunit "BCS Player Charge";
        BotDesignation: Code[20];

    begin
        Template.Get(WhichTemplate);
        BotDesignation := GenerateDesignator();

        // Charge the Materials to the Player
        if ResCheckBuffer.FindSet() then
            repeat
                if (ResCheckBuffer."Item No." = '') then
                    DoCashChargeForBot(ResCheckBuffer.Requirement, BCSPlayerCharge, BotDesignation)
                else
                    BCSPlayerCharge.ChargeMaterial(ResCheckBuffer."Item No.", ResCheckBuffer.Requirement, BotDesignation, StrSubstNo(BotPurchTok, BotDesignation));
            until ResCheckBuffer.Next() = 0;

        // Create the Bot Instance
        ExecuteBotPurchFromTemplate(Template, Instance, BotDesignation);

        exit(Instance.Designation);
    end;

    procedure InitialPurchaseBot(WhichTemplate: Code[20]): Text[20]
    var
        Template: Record "BCS Bot Template";
        Instance: Record "BCS Bot Instance";
        BCSPlayerCharge: Codeunit "BCS Player Charge";
        BotDesignation: Code[20];
    begin
        // Function is a copy of above, but only considers Cash, since this is used during
        // initial company setup and only the cash values are considered.
        Template.Get(WhichTemplate);
        BotDesignation := GenerateDesignator();

        // Charge the Cash to the Player
        DoCashChargeForBot(Template."Base Price", BCSPlayerCharge, BotDesignation);

        // Create the Bot Instance
        ExecuteBotPurchFromTemplate(Template, Instance, BotDesignation);

        exit(Instance.Designation);
    end;

    local procedure GenerateDesignator(): Text[10]
    var
        NewDesig: TextBuilder;
        Letter: Text[1];
    begin
        //A = 65 Z = 90
        Letter[1] := Random(26) + 64;
        NewDesig.Append(Letter);
        Letter[1] := Random(26) + 64;
        NewDesig.Append(Letter);
        NewDesig.Append('-');
        NewDesig.Append(Format(Random(9)) + Format(Random(9)) + Format(Random(9)));

        exit(CopyStr(NewDesig.ToText(), 1, 10));
    end;

    local procedure DoCashChargeForBot(AmountToCharge: Decimal; var BCSPlayerCharge: Codeunit "BCS Player Charge"; var BotDesignation: Code[20]) returnValue: Boolean
    var
        GameSetup: Record "BCS Game Setup";
    begin
        GameSetup.Get();
        returnValue := BCSPlayerCharge.ChargeCash(GameSetup."FA Value Account Bot", AmountToCharge, BotDesignation, StrSubstNo(BotPurchTok, BotDesignation));
    end;

    local procedure ExecuteBotPurchFromTemplate(var Template: Record "BCS Bot Template"; var Instance: Record "BCS Bot Instance"; var BotDesignation: Code[20])
    begin
        Instance.Init();
        Instance."Bot Type" := Template."Bot Type";
        Instance."Bot Tier" := Template."Bot Tier";
        Instance."Bot Template Code" := Template.Code;
        Instance."Power Per Day" := Template."Base Power Per Day";
        Instance."Operations Per Day" := Template."Base Operations Per Day";
        Instance.Price := Template."Base Price";
        Instance.Validate(Designation, BotDesignation);

        case Template."Bot Type" of
            Template."Bot Type"::Research:
                Instance."Research Points Per Op" := Template."Research Points Per Op";
        end;
        Instance.Insert(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateTemplatePrice(WhichTemplate: Record "BCS Bot Template"; var PriceToChargePlayerForBot: Decimal)
    begin
    end;

    procedure GenerateReqBuffer(var ResCheckBuffer: Record "BCS Resource Check Buffer"; WhichTemplate: Record "BCS Bot Template")
    var
        GLAccount: Record "G/L Account";
        Item: Record Item;
        GameSetup: Record "BCS Game Setup";
        TemplateReq: Record "BCS Bot Template Req.";
        MasterItem: Record "BCS Master Item";
        NextLineNo: Integer;
        PriceToChargePlayerForBot: Decimal;
    begin
        GameSetup.Get();

        // Always do Cash first
        ResCheckBuffer."Line No." := 1;
        ResCheckBuffer.Description := StrSubstNo(CashTok);
        PriceToChargePlayerForBot := WhichTemplate."Base Price";
        OnBeforeCalculateTemplatePrice(WhichTemplate, PriceToChargePlayerForBot);
        ResCheckBuffer.Requirement := PriceToChargePlayerForBot;
        GLAccount.Get(GameSetup."Cash Account");
        GLAccount.CalcFields(Balance);
        ResCheckBuffer.Inventory := GLAccount.Balance;
        ResCheckBuffer.Shortage := ResCheckBuffer.Inventory < ResCheckBuffer.Requirement;
        if (ResCheckBuffer.Shortage) then
            ResCheckBuffer.LineStyle := 'attention'
        else
            ResCheckBuffer.LineStyle := 'standard';
        ResCheckBuffer.Insert();
        NextLineNo := 2;

        //for each Temp. Req., create an entry, calc on-hand
        TemplateReq.SetRange("Bot Template Code", WhichTemplate.Code);
        if TemplateReq.FindSet() then
            repeat
                ResCheckBuffer."Line No." := NextLineNo;
                NextLineNo := NextLineNo + 1;
                MasterItem.Get(TemplateReq."Master Item No.");
                ResCheckBuffer."Item No." := MasterItem."No.";
                ResCheckBuffer.Description := MasterItem.Description;
                ResCheckBuffer.Requirement := TemplateReq.Quantity;
                if (Item.Get(TemplateReq."Master Item No.")) then begin
                    Item.CalcFields(Inventory);
                    ResCheckBuffer.Inventory := Item.Inventory;
                end else
                    ResCheckBuffer.Inventory := 0;
                ResCheckBuffer.Shortage := ResCheckBuffer.Inventory < ResCheckBuffer.Requirement;
                if (ResCheckBuffer.Shortage) then
                    ResCheckBuffer.LineStyle := 'attention'
                else
                    ResCheckBuffer.LineStyle := 'standard';
                ResCheckBuffer.Insert();
            until TemplateReq.Next() = 0;
    end;

    var
        CashTok: Label 'Money';
        BotPurchTok: Label 'Charge for purchase of %1.', Comment = '%1 is the code for what was purchased.';
}