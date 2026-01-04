require 'rails_helper'

RSpec.describe SpendingReport, type: :model do
  describe "validations" do
    it { should validate_uniqueness_of(:data_gov_id).allow_nil }
    it { should validate_presence_of(:amount) }
    it { should validate_presence_of(:description) }
  end

  describe "scopes" do
    describe ".filter_by_text" do
      let!(:report1) { create(:spending_report, description: "Office Chairs", agency_name: "Admin Dept") }
      let!(:report2) { create(:spending_report, description: "Road Work", agency_name: "Transport Dept") }

      it "finds records by description" do
        expect(SpendingReport.filter_by_text("Chairs")).to include(report1)
        expect(SpendingReport.filter_by_text("Chairs")).not_to include(report2)
      end

      it "finds records by agency name" do
        expect(SpendingReport.filter_by_text("Transport")).to include(report2)
        expect(SpendingReport.filter_by_text("Transport")).not_to include(report1)
      end
    end
  end
end
