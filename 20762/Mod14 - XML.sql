CREATE TABLE HR_XML (ID INT IDENTITY, Salaries XML)
GO
INSERT HR_XML VALUES(
    '<Salaries>
      <Marketing>
        <Employee ID="1" tier="4">
          <Salary>42000</Salary>
        </Employee>
        <Employee ID="2" tier="1">
          <Salary>52000</Salary>
        </Employee>
        <Employee ID="3" tier="4">
          <Salary>48000</Salary>
        </Employee>
      </Marketing>
    </Salaries>
    '
)
GO
--Inserting Nodes
UPDATE HR_XML
SET Salaries.modify('insert <Accounting /> into (/Salaries)[1]')
GO
--Insert Node as First
UPDATE HR_XML
SET Salaries.modify('insert <Accounting /> as first into (/Salaries)[1]')
GO
UPDATE HR_XML
SET Salaries.modify('insert <Employee ID="4" tier="4" /> into (/Salaries/Accounting)[3]')
GO
--Insert by Identifying a Specific Node
UPDATE HR_XML
SET Salaries.modify('insert <Projects /> into (/Salaries/Marketing/Employee[@ID=("2")])[1]')
GO
--Insert Nodes with Values
UPDATE HR_XML
SET Salaries.modify('insert <Project ID="1"><Description>Organize new strategies</Description></Project> 
						into (/Salaries/Marketing/Employee[@ID=("2")]/Projects)[1]')
GO
--Insert Nodes with Values from Other Nodes
UPDATE HR_XML
SET Salaries.modify('insert 
<Salary>{(/Salaries/Marketing/Employee[@ID=("1")]/Salary/text())}</Salary> 
into (/Salaries/Accounting/Employee[@ID=("4")])[1]')
GO
--Deleting Nodes
UPDATE HR_XML
SET Salaries.modify('delete (/Salaries/Accounting)[2]')
GO
--Deleting Values
UPDATE HR_XML
SET Salaries.modify('delete 
(/Salaries/Marketing/Employee[@ID=("2")]/Projects/Project[@ID="1"]/Description/text())[1]')
GO
--Replacing Values
UPDATE HR_XML
SET Salaries.modify('replace value of 
(/Salaries/Marketing/Employee[@ID=("2")]/Salary/text())[1] with ("60000")')
GO
SELECT * FROM HR_XML