// swiftlint:disable all
import Amplify
import Foundation

// Contains the set of classes that conforms to the `Model` protocol. 

final public class AmplifyModels: AmplifyModelRegistration {
  public let version: String = "3662af5c575e639fc60cb81d7906b93a"
  
  public func registerModels(registry: ModelRegistry.Type) {
    ModelRegistry.register(modelType: Worksheet.self)
    ModelRegistry.register(modelType: Question.self)
    ModelRegistry.register(modelType: SolutionFeedback.self)
    ModelRegistry.register(modelType: FullWorksheetSolution.self)
    ModelRegistry.register(modelType: UserStats.self)
    ModelRegistry.register(modelType: UserProfile.self)
    ModelRegistry.register(modelType: Classroom.self)
    ModelRegistry.register(modelType: ClassroomMembership.self)
    ModelRegistry.register(modelType: ParentChildRelationship.self)
    ModelRegistry.register(modelType: Homework.self)
    ModelRegistry.register(modelType: HomeworkAnalytics.self)
    ModelRegistry.register(modelType: StudentProgress.self)
    ModelRegistry.register(modelType: WorksheetMetadata.self)
    ModelRegistry.register(modelType: QuestionMetadata.self)
    ModelRegistry.register(modelType: ConceptMastery.self)
    ModelRegistry.register(modelType: ErrorPattern.self)
    ModelRegistry.register(modelType: PracticeProblem.self)
    ModelRegistry.register(modelType: PracticeAssignment.self)
    ModelRegistry.register(modelType: StudentAnalyticsSummary.self)
    ModelRegistry.register(modelType: CurriculumStandard.self)
    ModelRegistry.register(modelType: CurriculumTopicSummary.self)
    ModelRegistry.register(modelType: StudentCurriculumProgress.self)
  }
}