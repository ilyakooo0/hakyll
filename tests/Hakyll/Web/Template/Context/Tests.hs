--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
module Hakyll.Web.Template.Context.Tests
    ( tests
    ) where


--------------------------------------------------------------------------------
import           Test.Tasty                  (TestTree, testGroup)
import           Test.Tasty.HUnit            (Assertion, testCase, (@=?))


--------------------------------------------------------------------------------
import           Hakyll.Core.Compiler
import           Hakyll.Core.Identifier
import           Hakyll.Core.Item
import           Hakyll.Core.Provider
import           Hakyll.Core.Store           (Store)
import           Hakyll.Web.Template.Context
import           Hakyll.Web.Template.Internal
import           TestSuite.Util


--------------------------------------------------------------------------------
tests :: TestTree
tests = testGroup "Hakyll.Web.Template.Context.Tests"
    [ testCase "testDateField" testDateField
    , testCase "testOuerLoopContextAccess" testOuerLoopContextAccess
    ]


--------------------------------------------------------------------------------
testDateField :: Assertion
testDateField = do
    store    <- newTestStore
    provider <- newTestProvider store

    date1 <- testContextDone store provider "example.md" "date" $
        dateField "date" "%B %e, %Y"
    date1 @=? "October 22, 2012"

    date2 <- testContextDone store provider
        "posts/2010-08-26-birthday.md" "date" $
            dateField "date" "%B %e, %Y"
    date2 @=? "August 26, 2010"

    date3 <- testContextDone store provider
        "posts/2018-09-26.md" "date" $
            dateField "date" "%B %e, %Y"
    date3 @=? "September 26, 2018"

    date4 <- testContextDone store provider
        "posts/2019/05/10/tomorrow.md" "date" $
            dateField "date" "%B %e, %Y"
    date4 @=? "May 10, 2019"
    cleanTestEnv


--------------------------------------------------------------------------------
testContextDone :: Store -> Provider -> Identifier -> String
                -> Context String -> IO String
testContextDone store provider identifier key context =
    testCompilerDone store provider identifier $ do
        item <- getResourceBody
        cf   <- unContext context key [] item
        case cf of
            StringField str -> return str
            _               -> error $
                "Hakyll.Web.Template.Context.Tests.testContextDone: " ++
                "expected StringField"

--------------------------------------------------------------------------------

testOuerLoopContextAccess :: Assertion
testOuerLoopContextAccess = do
    store    <- newTestStore
    provider <- newTestProvider store
    test store provider ctx "baz"
    test store provider (ctx' <> ctx) "not baz"
    test store provider (ctx <> ctx') "baz"

    cleanTestEnv
    where
        tpl = readTemplate "$for(foo)$$for(bar)$$qux$$endfor$$endfor$"
        ctx = mconcat [
            field "qux" $ const $ return "baz"
            , listField "foo" (listField "bar" mempty $ return [mockItem])
                $ return [mockItem]
            ]
        ctx' = field "qux" $ const $ return "not baz"
        mockItem = Item "" ()
        test store provider context str = do
            str' <- testCompilerDone store provider ""
                $ applyTemplate tpl context mockItem
            str @=? itemBody str'
