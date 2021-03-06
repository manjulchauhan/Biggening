page 88001 "BCS Setup Overview"
{
    Caption = 'Setup Overview';
    PageType = ListPart;
    UsageCategory = Lists;
    ApplicationArea = All;
    SourceTable = Company;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Name; Name)
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Specifies the value of the Name field';
                }
                field("Display Name"; "Display Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Display Name field';
                }
                field(MasterCompany; MasterCompany)
                {
                    ApplicationArea = All;
                    Caption = 'Master Company';
                    ToolTip = 'Specifies the value of the Master Company field';
                }
                field(GLAccountFld; SetupTableCounts[1])
                {
                    ApplicationArea = All;
                    Caption = 'G/L Account';
                    ToolTip = 'Specifies the value of the G/L Account field';
                }
                field(GenBusPostingFld; SetupTableCounts[2])
                {
                    ApplicationArea = All;
                    Caption = 'Gen. Bus. Posting';
                    ToolTip = 'Specifies the value of the Gen. Bus. Posting field';
                }

                field(GenProdPostingFld; SetupTableCounts[3])
                {
                    ApplicationArea = All;
                    Caption = 'Gen. Prod Posting';
                    ToolTip = 'Specifies the value of the Gen. Prod Posting field';
                }

                field(GenPostingSetupFld; SetupTableCounts[4])
                {
                    ApplicationArea = All;
                    Caption = 'Gen. Posting Setups';
                    ToolTip = 'Specifies the value of the Gen. Posting Setups field';
                }

                field(CustPostingGroupsFld; SetupTableCounts[5])
                {
                    ApplicationArea = All;
                    Caption = 'Cust. Posting Groups';
                    ToolTip = 'Specifies the value of the Cust. Posting Groups field';
                }

                field(CustDiscGroupsFld; SetupTableCounts[6])
                {
                    ApplicationArea = All;
                    Caption = 'Cust. Disc. Groups';
                    ToolTip = 'Specifies the value of the Cust. Disc. Groups field';
                }

                field(PaymentTermsFld; SetupTableCounts[7])
                {
                    ApplicationArea = All;
                    Caption = 'Payment Terms';
                    ToolTip = 'Specifies the value of the Payment Terms field';
                }

                field(VendPostingGroupsFld; SetupTableCounts[8])
                {
                    ApplicationArea = All;
                    Caption = 'Vendor Posting Groups';
                    ToolTip = 'Specifies the value of the Vendor Posting Groups field';
                }

                field(InvPostingGroupsFld; SetupTableCounts[9])
                {
                    ApplicationArea = All;
                    Caption = 'Inventory Posting Groups';
                    ToolTip = 'Specifies the value of the Inventory Posting Groups field';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CopyTO)
            {
                ApplicationArea = All;
                Caption = 'Copy To...';
                ToolTip = 'Executes the Copy To... action';

                trigger OnAction();
                var
                    BCSMaster: Codeunit "BCS Master Company";
                begin
                    BCSMaster.CopySetupToCompany(Rec.Name);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        GetSetupCounts(Rec.Name);
        IsMasterCompany(Rec.Name);
    end;

    local procedure IsMasterCompany(WhichCompany: Text[30])
    var
        CompanyInformation: Record "Company Information";
    begin
        MasterCompany := false;
        CompanyInformation.ChangeCompany(WhichCompany);
        if CompanyInformation.get() then
            MasterCompany := CompanyInformation."Master Company";
    end;

    local procedure GetSetupCounts(WhichCompany: Text[30])
    var
        GLAccount: Record "G/L Account";
        GenBusPosting: Record "Gen. Business Posting Group";
        GenProdPosting: Record "Gen. Product Posting Group";
        GenPostingSetup: Record "General Posting Setup";
        CustPostingGroups: Record "Customer Posting Group";
        CustDiscGroups: Record "Customer Discount Group";
        PaymentTerms: Record "Payment Terms";
        VendPostingGroups: Record "Vendor Posting Group";
        InvPostingGroups: Record "Inventory Posting Group";
    begin
        Clear(SetupTableCounts);
        GLAccount.ChangeCompany(WhichCompany);
        SetupTableCounts[1] := GLAccount.Count;
        GenBusPosting.ChangeCompany(WhichCompany);
        SetupTableCounts[2] := GenBusPosting.Count;
        GenProdPosting.ChangeCompany(WhichCompany);
        SetupTableCounts[3] := GenProdPosting.Count;
        GenPostingSetup.ChangeCompany(WhichCompany);
        SetupTableCounts[4] := GenPostingSetup.Count;
        CustPostingGroups.ChangeCompany(WhichCompany);
        SetupTableCounts[5] := CustPostingGroups.Count;
        CustDiscGroups.ChangeCompany(WhichCompany);
        SetupTableCounts[6] := CustDiscGroups.Count;
        PaymentTerms.ChangeCompany(WhichCompany);
        SetupTableCounts[7] := PaymentTerms.Count;
        VendPostingGroups.ChangeCompany(WhichCompany);
        SetupTableCounts[8] := VendPostingGroups.Count;
        InvPostingGroups.ChangeCompany(WhichCompany);
        SetupTableCounts[9] := InvPostingGroups.Count;
    end;

    var
        SetupTableCounts: Array[9] of Integer;
        MasterCompany: Boolean;
}