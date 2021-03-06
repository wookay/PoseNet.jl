export prepare, getpose, getpaf

using PyCall

# https://github.com/dhoegh/Hawk.jl/blob/master/src/Hawk.jl

filename = abspath(joinpath(dirname(@__FILE__), "convert.py"))

@pyimport imp
(path, name) = dirname(filename), basename(filename)
(name, ext) = rsplit(name, '.')

(file, filename, data) = imp.find_module(name, [path])
conv = imp.load_module(name, file, filename, data)


struct PoseModel
    param
    model
    net
end


const colors = [[255, 0, 0], [255, 85, 0], [255, 170, 0], [255, 255, 0], [170, 255, 0], [85, 255, 0], [0, 255, 0],
          [0, 255, 85], [0, 255, 170], [0, 255, 255], [
              0, 170, 255], [0, 85, 255], [0, 0, 255], [85, 0, 255],
          [170, 0, 255], [255, 0, 255], [255, 0, 170], [255, 0, 85]]

function prepare(;gpu=false)::PoseModel
    param, model, net = conv[:prepare](gpu)
    PoseModel(param, model, net)
end

function getpose(posem::PoseModel, image::String; currentFrame=1, format="image")
    oriImg, multiplier, heatmap, paf = conv[:netforward](posem.param, posem.model, posem.net, image)
    conv[:convert](currentFrame, oriImg, multiplier, heatmap, paf, colors, format)
end

function getpose(posem::PoseModel, list::Vector; format="image")
    for (currentFrame, image) in enumerate(list)
        getpose(posem, image; currentFrame=currentFrame, format=format)
    end
end

function getpaf(posem::PoseModel, list::Vector)::Vector
    pafs = []
    for (currentFrame, image) in enumerate(list)
        push!(pafs, getpaf(posem, image; currentFrame=currentFrame))
    end
    pafs
end

function getpaf(posem::PoseModel, image::String; currentFrame=1)
    oriImg, multiplier, heatmap, paf = conv[:netforward](posem.param, posem.model, posem.net, image, false)
    conv[:paf_info](currentFrame, oriImg, multiplier, heatmap, paf, colors)
end
