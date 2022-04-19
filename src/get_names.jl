using Pkg
Pkg.activate(".")
using HTTP
using DotEnv
using JSON3
using DataFrames
using DataFramesMeta
using BitHelper
using CSV
using Downloads
using Dates
using StringDistances
using Unicode

DotEnv.config()

# configure bit.io
bit.install_key!(ENV["BITIO_PG_STRING"])

# Function for Downloading Data from Senate/House Stock Watchers
function download_transactions(chamber, overwrite = false; path = "./data/")
    if !isdir(path)
        mkdir(path)
    end
    if chamber == "senate"
        url = "https://senate-stock-watcher-data.s3-us-west-2.amazonaws.com/aggregate/all_transactions.csv"
    elseif chamber == "house"
        url = "https://house-stock-watcher-data.s3-us-west-2.amazonaws.com/data/all_transactions.csv"
    else
        @error("Please enter house or senate")
    end
    out = "$(path)transactions_$(chamber)_$(today()).csv"
    if isfile(out)
        if overwrite
            Downloads.download(url, out)
        else
            print("File exists. Specify overwrite=true to download again.")
        end
    else
        Downloads.download(url, out)
    end
end

# Download Names from ProPublica API
function download_propublica_member_names(overwrite=false; path="./data/")
    # setup
    headers = ["X-API-Key" => ENV["PROPUBLICA_KEY"]]
    ids = Dict("senate" => [], "house" => [])
    committee_dict = Dict("member" => [],
                          "chamber" => [])
                          
    for chamber in ["house", "senate"]
        local ids = []
        local url = "https://api.propublica.org/congress/v1/117/$(chamber)/members.json"
        local r = HTTP.request("GET", url, headers)
        local rj = JSON3.read(r.body)
        for member in rj[:results][1][:members]
            push!(committee_dict["member"], "$(member[:first_name]) $(member[:middle_name]) $(member[:last_name]) $(member[:suffix])")
            push!(committee_dict["chamber"], chamber)
        end
    end

    out = "$(path)propublica_names.csv"
    if isfile(out)
        if overwrite
            CSV.write(out, DataFrame(committee_dict))
        else
            print("File exists. Specify overwrite=true to download again.")
        end
    else
        CSV.write(out, DataFrame(committee_dict))
    end
end



# Download Data
download_transactions("senate", true)
download_transactions("house", true)
download_propublica_member_names(true)
