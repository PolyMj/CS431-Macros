local base64_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

-- Base64 encoding function (Totally not from ChatGPT)
function tob64(num)
    local result = ""
    while num > 0 do
        local index = num % 64 + 1
        result = string.sub(base64_chars, index, index) .. result
        num = math.floor(num / 64)
    end
    return result
end

-- Base64 decoding function (Also not at all copied from ChatGPT)
function fromb64(str)
    local num = 0
    for i = 1, #str do
        local char = string.sub(str, i, i)
        local index = string.find(base64_chars, char)
        num = num * 64 + (index - 1)
    end
    return num
end