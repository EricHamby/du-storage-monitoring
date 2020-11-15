local storage_elements = {}

for _,id in pairs(elementsIdList) do
    local elementType = core.getElementTypeById(id)
    if elementType:lower():find("container") then
        local elementName = core.getElementNameById(id)
        if elementName:lower():find(containerMonitoringPrefix:lower()) then
            local container = {}
            local splitted = strSplit(elementName, '_')
            local name = splitted[2]
            local ingredient = getIngredient(cleanName(name))
            local container_size = "XS"
            local container_amount = 1
            local container_empty_mass = 0
            local container_volume = 0
            local contentQuantity = 0
            local percent_fill = 0
            if not elementType:lower():find("hub") then
                local containerMaxHP = core.getElementMaxHitPointsById(id)
                if containerMaxHP > 17000 then
                    container_size = "L"
                    container_empty_mass = getIngredient("Container L").mass
                    container_volume = 128000 * (container_proficiency_lvl * 0.1) + 128000
                elseif containerMaxHP > 7900 then
                    container_size = "M"
                    container_empty_mass = getIngredient("Container M").mass
                    container_volume = 64000 * (container_proficiency_lvl * 0.1) + 64000
                elseif containerMaxHP > 900 then
                    container_size = "S"
                    container_empty_mass = getIngredient("Container S").mass
                    container_volume = 8000 * (container_proficiency_lvl * 0.1) + 8000
                else
                    container_size = "XS"
                    container_empty_mass = getIngredient("Container XS").mass
                    container_volume = 1000 * (container_proficiency_lvl * 0.1) + 1000
                end
            else
                if splitted[3] then
                    container_size = splitted[3]
                end
                if splitted[4] then
                    container_amount = splitted[4]
                end
                local volume = 0
                if container_size:lower() == "l" then volume = 128000
                elseif container_size:lower() == "m" then volume = 64000
                elseif container_size:lower() == "s" then volume = 8000
                elseif container_size:lower() == "xs" then volume = 1000
                end
                container_volume = volume * (container_proficiency_lvl * 0.1) + volume
                container_volume = container_volume * container_amount
                container_empty_mass = getIngredient("Container Hub").mass
            end
            local totalMass = core.getElementMassById(id)
            local contentMassKg = totalMass - container_empty_mass
            container.id = id
            container.name = name
            container.ingredient = ingredient
            container.quantity = contentMassKg / ingredient.mass
            container.volume = container_volume
            container.percent = utils.round((ingredient.volume * container.quantity) * 100 / container_volume)
            if ingredient.name == "unknown" then
                container.percent = 0
            end
            table.insert(storage_elements, container)
        end
    end
end

-- group by name
local groupped = {}
if groupByItemName then
    for _,v in pairs(storage_elements) do
        if groupped[v.ingredient.name] then
            groupped[v.ingredient.name].quantity = groupped[v.ingredient.name].quantity + v.quantity
            groupped[v.ingredient.name].volume = groupped[v.ingredient.name].volume + v.volume
            groupped[v.ingredient.name].percent = (v.ingredient.volume * groupped[v.ingredient.name].quantity) * 100 / groupped[v.ingredient.name].volume
        else
            groupped[v.ingredient.name] = v
        end
    end
else
    groupped = storage_elements
end

-- sorting by tier
local tiers = {}
tiers[1] = {}
tiers[2] = {}
tiers[3] = {}
tiers[4] = {}
tiers[5] = {}
for _,v in pairs(groupped) do
    table.insert(tiers[v.ingredient.tier],v)
end

-- sorting by name
for k,v in pairs(tiers) do
    table.sort(tiers[k], function(a,b) return a.ingredient.name:lower() < b.ingredient.name:lower() end)
end

if screen ~= nil then
    local css = [[
        <style>
    	   * {
    		  font-size: 1.5vw;
    		  font-weight: bold;
    		  color: white;
    	   }
            .screenContent {
                position:absolute;
                top:0;
                left:0;
                width: 100vw;
                heigth:100vh;
            }
    	   table {
    		  width:100vw;
    		  border:3px solid orange;
    	   }
    	   th, td {
    		  border:3px solid orange;
		  }
            .text-orangered{color:orangered;}
            .bg-success{background-color: #28a745;}
            .bg-danger{background-color:#dc3545;}
            .bg-warning{background-color:#ffc107;}
            .bg-info{background-color:#17a2b8;}
            .bg-primary{background-color:#007bff;}
        </style>
    ]]
    local html = [[
    	<table>
    		<thead>
    			<tr>
    				<th>Tier</th>
    				<th>Container Name</th>
    				<th>Capacity</th>
    				<th>Item Name</th>
    				<th>Amount</th>
    				<th>Percent Fill</th>
    			</tr>
    		</thead>
    		<tbody>
    ]]

    for tier_k,tier in pairs(tiers) do
        for _,container in pairs(tier) do
            local gauge_color_class = "bg-success"
            local text_color_class = ""
            if container.percent < container_fill_red_level then
                gauge_color_class = "bg-danger"
            elseif  container.percent < container_fill_yellow_level then
                gauge_color_class = "bg-warning"
                text_color_class = "text-orangered"
            end
            html = html .. [[
                <tr>
                    <th>]] .. tier_k .. [[</th>
                    <th>]] .. container.name .. [[</th>
                    <th>]] .. format_number(container.volume) .. [[L</th>
                    <th>]] .. container.ingredient.name .. [[</th>
                    <th>]] .. format_number(utils.round(container.quantity * 100) / 100) .. [[</th>
                    <th style="position:relative;width: ]] .. tostring((750/1920)*100) .. [[vw;">
                        <div class="]] .. gauge_color_class .. [[" style="width:]] .. container.percent .. [[%;">&nbsp;</div>
                        <div class="]] .. text_color_class .. [[" style="position:absolute;width:100%;top:50%;font-weight:bold;transform:translateY(-50%);">
                            ]] .. format_number(utils.round(container.percent * 100) / 100) .. [[%
                        </div>
                    </th>
                </tr>
            ]]
        end
    end
    html = html .. [[</tbody></table>]]
    screen.setHTML(css .. html)
end