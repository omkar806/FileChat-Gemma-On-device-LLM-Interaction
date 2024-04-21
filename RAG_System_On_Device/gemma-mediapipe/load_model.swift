

import Foundation
import MediaPipeTasksGenAI


func initialise_llm()->LlmInference{
    let modelPath = Bundle.main.path(forResource: "gemma-2b-it-cpu-int4",
                                          ofType: "bin")!

    let options = LlmInference.Options(modelPath: modelPath)
    options.modelPath = modelPath
    options.maxTokens = 1000
    options.topk = 40
    options.temperature = 0.8
    options.randomSeed = 101
    
    let LlmInference = try LlmInference(options: options)
    return LlmInference
}


