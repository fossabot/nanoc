# frozen_string_literal: true

describe 'types', chdir: false do
  example do
    RDL.do_typecheck(:spec)
  end
end
